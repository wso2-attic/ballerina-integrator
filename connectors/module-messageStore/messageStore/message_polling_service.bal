// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/jms;
import ballerina/log;
import ballerina/io;

//service with steps done upon message processor task trigger
service messageForwardingService = service {

    resource function onTrigger(PollingServiceConfig config) {

        function () onMessagePollingFailFunction = config.onMessagePollingFail;
        jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
        //wait for 1 second until you receive a message. If no message is received nil is returned
        var queueMessage = caller->receive(timeoutInMilliSeconds = 1000);
        if (queueMessage is jms:Message) {
            var httpRequest = constructHTTPRequest(queueMessage);
            if(httpRequest is http:Request) {
                //invoke the backend using HTTP Client, it will use receliecy parameters
                http:Client clientEP = config.httpClient;
                var response = clientEP->post("", httpRequest);
                evaluateForwardSuccess(config, httpRequest, response, queueMessage);
            } else {
                log:printError("Error occurred while converting message received from queue " 
                            + config.queueName + " to an HTTP request");
            }

        } else if (queueMessage is ()) {
            log:printDebug("Message not received on current trigger");
        } else {
            // Error when message receival. Need to reset the connection. session and consumer 
            log:printError("Error occurred while receiving message from queue " + config.queueName);
            onMessagePollingFailFunction.call();
        }
    }
  
};

# Evaluate if HTTP response forwarding is success or failure and take actions. 
#
# + response - `http:Response` or `error` received from forwarding the message  
# + config - Message processor config `PollingServiceConfig` 
# + queueMessage - Message polled from the queue `jms:Message`
# + request - HTTP request forwarded `http:Request`
function evaluateForwardSuccess(PollingServiceConfig config, http:Request request, 
        http:Response | error response, jms:Message queueMessage) {
    //in case of retry status codes specified, HTTP client will retry but a response
    //will be received. Still in case of forwarding we need to consider it as a failure 
    if (response is http:Response) {
        boolean isFailingResponse = false;
        int[] retryHTTPCodes = config.retryHTTPCodes;
        foreach var statusCode in retryHTTPCodes {
            if (statusCode == response.statusCode) {
                isFailingResponse = true;
                break;
            }
        }
        if(isFailingResponse) {
            //Failure. Response has failure HTTP status code 
            onMessageForwardingFail(config, request, queueMessage);
        } else {
            //success. Ack the message
            jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
            var ack = caller->acknowledge(queueMessage);
            if (ack is error) {
                log:printError("Error occurred while acknowledging message", err = ack);
            }
            config.handleResponse.call(response); 
        }
    } else {
        //Failure. Connection level issue
        onMessageForwardingFail(config, request, queueMessage);
    }
}

# Take actions when message forwarding fails. 
#
# + config - cconfiguration for message processor `PollingServiceConfig` 
# + request - HTTP request `http:Request` failed to forward 
# + queueMessage - message received from the queue `jms:Message` that failed to process
function onMessageForwardingFail(PollingServiceConfig config, http:Request request, jms:Message queueMessage) {
    //if there is a DLC store is defined, store the message into that, if not drop the message
    Client? DLCStore = config["DLCStore"];
    if (DLCStore is Client) {
        log:printWarn("Maximum retires breached when forwading message to HTTP endpoint " + config.httpEP 
            + ". Forwarding message to DLC Store");
        var storeResult = DLCStore->store(request);
        if(storeResult is error) {
            log:printError("Error while forwarding message to DLC store. Message will be lost", err = storeResult);
        }
        jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
        var ack = caller->acknowledge(queueMessage);
        if (ack is error) {
            log:printError("Error occurred while acknowledging message",
                err = ack);
        }    
    } else if (config.deactivateOnFail) {
        log:printWarn("Maximum retires breached when forwading message to HTTP endpoint " + config.httpEP 
            + ". Message forwading is stopped for " + config.httpEP);
        //TODO : stop message processor
    } else {
        log:printWarn("Maximum retires breached when forwading message to HTTP endpoint " + config.httpEP 
            + ". Dropping message and continue");
                jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
        var ack = caller->acknowledge(queueMessage);
        if (ack is error) {
            log:printError("Error occurred while acknowledging message",
                err = ack);
        }     
    }  
}

# Reconstruct construct HTTP message from JMS message.
#
# + message - JMS message (map message) `jms:Message`  
# + return - HTTP request `http:Request`
function constructHTTPRequest(jms:Message message) returns http:Request | error {
    var messageContent = check message.getMapMessageContent();
    http:Request httpRequest = new();
    foreach (string, any) (key, value) in messageContent {
        if (key == PAYLOAD) {
            httpRequest.setPayload(untaint <string>value);        // TODO: should we parse the message here looking at content-type header?
        } else {
            httpRequest.setHeader(untaint key, <string>value);
        }
    }
    return httpRequest;
}



