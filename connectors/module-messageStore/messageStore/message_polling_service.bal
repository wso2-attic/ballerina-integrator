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

//service with steps done upon message processor task trigger
service messageForwardingService = service {

    resource function onTrigger(PollingServiceConfig config) {
        int messageCount = 0;
        while (config.batchSize == -1 || messageCount < config.batchSize) {
            ForwardStatus forwardStatus = pollAndForward(config);
            //if there is no message on message store or if processor should get deactivated on forwarding fail
            //need to immediately return from the loop
            if(!forwardStatus.success && (config.forwardingFailAction == DEACTIVATE) || forwardStatus.storeEmpty) {
                if(forwardStatus.storeEmpty) {
                    log:printDebug("Message store is empty. Queue = " + config.queueName 
                    + ". Message forwarding is stopped until next trigger");
                }
                break;
            }
            if(config.forwardingInterval > 0) {
                runtime:sleep(config.forwardingInterval);
            }
            messageCount = messageCount + 1;
        }
    }
};

# Poll a message from message store and forward it to defined endpoint.
#
# + config - Configuration for message processing service
# + return - `true` if message forwarding is successful
function pollAndForward(PollingServiceConfig config) returns ForwardStatus {
    boolean forwardSuccess = true;
    boolean messageStoreEmpty = false;
    function() onMessagePollingFailFunction = config.onMessagePollingFail;
    jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
    //wait for 1 second until you receive a message. If no message is received nil is returned
    var queueMessage = caller->receive(timeoutInMilliSeconds = 1000);
    if (queueMessage is jms:Message) {
        var httpRequest = constructHTTPRequest(queueMessage);
        if (httpRequest is http:Request) {
            //invoke pre-process logic
            if (config.preProcessRequest is function(http:Request request)) {
                config.preProcessRequest.call(httpRequest);
            }
            //invoke the backend using HTTP Client, it will use receliecy parameters
            http:Client clientEP = config.httpClient;
            string httpVerb = config.HttpOperation;
            var response = clientEP->execute(untaint httpVerb, "", httpRequest);
            forwardSuccess = evaluateForwardSuccess(config, httpRequest, response, queueMessage);
        } else {
            log:printError("Error occurred while converting message received from queue "
            + config.queueName + " to an HTTP request");
        }

    } else if (queueMessage is ()) {
        log:printDebug("Message not received on current trigger");
        forwardSuccess = false;
        messageStoreEmpty = true;
    } else {
        // Error when message receival. Need to reset the connection. session and consumer
        log:printError("Error occurred while receiving message from queue " + config.queueName);
        forwardSuccess = false;
        onMessagePollingFailFunction.call();
    }

    ForwardStatus forwardStatus = {
        success: forwardSuccess,
        storeEmpty: messageStoreEmpty
    };

    return forwardStatus;
}

# Evaluate if HTTP response forwarding is success or failure and take actions. 
#
# + response - `http:Response` or `error` received from forwarding the message  
# + config - Message processor config `PollingServiceConfig` 
# + queueMessage - Message polled from the queue `jms:Message`
# + request - HTTP request forwarded `http:Request`
# + return - `true` if message forwarding is a success
function evaluateForwardSuccess(PollingServiceConfig config, http:Request request,
http:Response | error response, jms:Message queueMessage) returns boolean {
    //in case of retry status codes specified, HTTP client will retry but a response
    //will be received. Still in case of forwarding we need to consider it as a failure
    boolean fowardSucess = true;
    if (response is http:Response) {
        boolean isFailingResponse = false;
        int[] retryHTTPCodes = config.retryHttpCodes;
        if (retryHTTPCodes.length() > 0) {
            foreach var statusCode in retryHTTPCodes {
                if (statusCode == response.statusCode) {
                    isFailingResponse = true;
                    break;
                }
            }
        }
        if (isFailingResponse) {
            //Failure. Response has failure HTTP status code
            fowardSucess = false;
            onMessageForwardingFail(config, request, queueMessage);
        } else {
            //success. Ack the message
            fowardSucess = true;
            jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
            var ack = caller->acknowledge(queueMessage);
            if (ack is error) {
                log:printError("Error occurred while acknowledging message", err = ack);
            }
            config.handleResponse.call(response);
        }
    } else {
        //Failure. Connection level issue
        fowardSucess = false;
        log:printError("Error when invoking the backend" + config.httpEP, err = response);
        onMessageForwardingFail(config, request, queueMessage);
    }
    return fowardSucess;
}

# Take actions when message forwarding fails. 
#
# + config - cconfiguration for message processor `PollingServiceConfig` 
# + request - HTTP request `http:Request` failed to forward 
# + queueMessage - message received from the queue `jms:Message` that failed to process
function onMessageForwardingFail(PollingServiceConfig config, http:Request request, jms:Message queueMessage) {
    if (config.forwardingFailAction == DEACTIVATE) {        //just deactivate the processor
        log:printWarn("Maximum retires breached when forwarding message to HTTP endpoint " + config.httpEP
        + ". Message forwading is stopped for " + config.httpEP);
        config.onDeactivate.call();
    } else if (config.forwardingFailAction == DLC_STORE) {        //if there is a DLC store defined, store the message into that
        log:printWarn("Maximum retires breached when forwarding message to HTTP endpoint " + config.httpEP
        + ". Forwarding message to DLC Store");
        Client? DLCStore = config["DLCStore"];
        if (DLCStore is Client) {
            var storeResult = DLCStore->store(request);
            if (storeResult is error) {
                log:printError("Error while forwarding message to DLC store. Message will be lost", err = storeResult);
            } else {
                ackMessage(config, queueMessage);
            }
        } else {
            log:printError("Error while forwarding message to DLC store. DLC store is not specified. Message will be lost");
            ackMessage(config, queueMessage);
        }
    } else {        //drop the message and continue
        log:printWarn("Maximum retires breached when forwarding message to HTTP endpoint " + config.httpEP
        + ". Dropping message and continue");
        ackMessage(config, queueMessage);
    }
}

# Reconstruct construct HTTP message from JMS message.
#
# + message - JMS message (map message) `jms:Message`  
# + return - HTTP request `http:Request`
function constructHTTPRequest(jms:Message message) returns http:Request | error {
    var messageContent = check message.getMapMessageContent();
    http:Request httpRequest = new();
    byte[] payload = <byte[]>messageContent.PAYLOAD;
    httpRequest.setBinaryPayload(untaint payload);
    foreach (string, any) (key, value) in messageContent {
        if (key != PAYLOAD) {
            httpRequest.setHeader(untaint key, <string>value);
        }
    }
    return httpRequest;
}


# Acknowledge message.
#
# + config - Config for message processor service `PollingServiceConfig`  
# + queueMessage - Message to acknowledge `jms:Message`
function ackMessage(PollingServiceConfig config, jms:Message queueMessage) {
    jms:QueueReceiverCaller caller = config.queueReceiver.getCallerActions();
    var ack = caller->acknowledge(queueMessage);
    if (ack is error) {
        log:printError("Error occurred while acknowledging message", err = ack);
    }
}

# Record carrying information on message forwarding status
#
# + success - `true` if forwarding message is successful
# + storeEmpty - `true` if message store is empty and no message is received
public type ForwardStatus record {
    boolean success;
    boolean storeEmpty;
};
