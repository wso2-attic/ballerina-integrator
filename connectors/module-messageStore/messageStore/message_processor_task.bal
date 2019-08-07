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

import ballerina/jms;
import ballerina/task;
import ballerina/log;
import ballerina/runtime;
import ballerina/math;
import ballerina/http;


# Definition of forwarding Processor object. It polls messages from Message Broker
# pointed and forwards messages to the configred HTTP endpoint with reliability. 
public type MessageForwardingProcessor object {

    //TODO: remove after (ballerina-lang/issues/16201)
    boolean active;

    ForwardingProcessorConfiguration processorConfig;

    //objects related to JMS connection
    jms:Connection jmsConnection;
    jms:Session jmsSession;
    jms:QueueReceiver queueReceiver;

    //HTTP client used to forward messages to HTTP endpoint
    http:Client httpClient;

    //task driving the message polling from the broker and forward
    task:Scheduler messageForwardingTask;

    # Initialize `MessageForwardingProcessor` object. This will create necessary
    # connnections to the configured message broker and configured backend. Polling 
    # of messages is not started until `start` is called. 
    # 
    # + processorConfig - `ForwardingProcessorConfiguration` processor configuration 
    # + handleResponse  - `function (http:Response resp)` lamda to process the response from HTTP BE 
    #                      after forwarding the request by processor
    # + preProcessRequest - `function(http:Request requst)` lamda to process the request before forwarding to the backend
    # + return          - `error` if there is an issue initializing processor (i.e connection issue with broker)
    public function __init(ForwardingProcessorConfiguration processorConfig,
    function(http:Response resp) handleResponse, function(http:Request request)? preProcessRequest = ()) returns error? {
        self.active = true;
        self.processorConfig = processorConfig;

        MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);
        string acknowledgementMode = CLIENT_ACKNOWLEDGE;
        string queueName = storeConfig.queueName;

        //if retry config is not set, set one with defaults 
        if(storeConfig.retryConfig == ()) {
            storeConfig.retryConfig = {
                count: -1,  //infinite retry until success
                interval: 5,
                backOffFactor: 1.5,
                maxWaitInterval: 60
            };
        }

        //init connection to the broker
        var consumerInitResult = check trap initializeConsumer(storeConfig);
        (self.jmsConnection, self.jmsSession, self.queueReceiver) = consumerInitResult;

        //init HTTP endpoint
        self.httpClient = check self.initializeHTTPClient(processorConfig);

        // Check if a cron is mentioned in config. If so, it gets priority
        string | int currentpollTimeConfig = processorConfig.pollTimeConfig;
        if (currentpollTimeConfig is string) {
            self.messageForwardingTask = new({appointmentDetails: currentpollTimeConfig});
        } else {
            self.messageForwardingTask = new({interval: currentpollTimeConfig});
        }

        int[] retryHttpCodes = [];
        int[]? retryHttpCodesFromConfig = processorConfig["retryHttpStatusCodes"];
        if (retryHttpCodesFromConfig is int[]) {
            retryHttpCodes = retryHttpCodesFromConfig;
        }

        //create a record with objects needed by the polling service
        PollingServiceConfig pollingServiceConfig = {
            queueReceiver: self.queueReceiver,
            queueName: queueName,
            httpClient: self.httpClient,
            httpEP: processorConfig.HttpEndpointUrl,
            HttpOperation: processorConfig.HttpOperation,
            retryHttpCodes: retryHttpCodes,
            forwardingFailAction: processorConfig.forwardingFailAction,
            batchSize: processorConfig.batchSize,
            forwardingInterval: processorConfig.forwardingInterval,
            onMessagePollingFail: onMessagePollingFail(self),
            onDeactivate: onDeactivate(self),
            preProcessRequest: preProcessRequest,
            handleResponse: handleResponse,
            DLCStore: processorConfig["DLCStore"]
        };

        //attach the task work
        var assignmentResult = self.messageForwardingTask.attach(messageForwardingService,  attachment = pollingServiceConfig);
        if (assignmentResult is error) {
            log:printError("Error when attaching service to the message processor task ", err = assignmentResult);
            return assignmentResult;
        }
    }

    # Get name of the message broker queue this message processor is consuming messages from.
    #
    # + return - Name of the queue 
    public function getQueueName() returns string {
        return self.processorConfig.storeConfig.queueName;
    }

    # Start Message Processor. This will start polling messages from configured message broker 
    # and forward it to the backend. 
    #
    # + return - `error` in case of starting the polling task
    public function start() returns error? {
        check self.messageForwardingTask. start();
    }

    # Stop Messsage Processor. This will stop polling messages and forwarding.
    #
    # + return - `error` in case of stopping Message Processor
    public function stop() returns error? {
        check self.messageForwardingTask.stop();
        self.active = false;
    }

    # Keep main thread running 
    public function keepRunning() {
        //TODO: fix after (ballerina-lang/issues/16201)
        while (self.active) {
            runtime:sleep(1000);
        }
    }

    # Initialize HTTP client to forward messages.
    #
    # + processorConfig - `ForwardingProcessorConfiguration` config 
    # + return - `http:Client` in case of successful initialization or `error` in case of issue
    function initializeHTTPClient(ForwardingProcessorConfiguration processorConfig) returns http:Client | error {
        http:ClientEndpointConfig endpointConfig;
        http:RetryConfig retryConfig = {
            interval: processorConfig.retryInterval, //Retry interval in milliseconds
            count: processorConfig.maxRedeliveryAttempts,   //Number of retry attempts before giving up
            backOffFactor: 1.0, //Multiplier of the retry interval
            maxWaitInterval: 20000,  //Maximum time of the retry interval in milliseconds
            statusCodes: processorConfig.retryHttpStatusCodes //HTTP response status codes which are considered as failures 
        };
        var httpEndpointConfig = processorConfig.HttpEndpointConfig;
        if(httpEndpointConfig is http:ClientEndpointConfig) {
            endpointConfig = httpEndpointConfig;
            endpointConfig.retryConfig = retryConfig;
        } else {
            endpointConfig = {
                retryConfig: retryConfig
            };
        }
        http:Client backendClientEP = new(processorConfig.HttpEndpointUrl, config = endpointConfig);
        return backendClientEP;
    }

    # Clean up JMS objects (connections, sessions and consumers). 
    #
    # + return - `error` in case of stopping and closing JMS objects
    function cleanUpJMSObjects() returns error? {
        check self.queueReceiver.__stop();
        //TODO: Ballerina has no method to close session
        //TODO: Ballerina has no method to close connection
        check trap self.jmsConnection.stop();
    }

    # Retry connecting to broker according to given config. This will try forever
    # until connection get successful.  
    function retryToConnectBroker(ForwardingProcessorConfiguration processorConfig) {
        MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
        int maxRetryCount = storeConfig.retryConfig.count;
        int retryInterval = storeConfig.retryConfig.interval;
        int maxRetryDelay = storeConfig.retryConfig.maxWaitInterval;
        int retryCount = 0;
        while (maxRetryCount == -1 || retryCount < maxRetryCount) {
            var consumerInitResult = trap initializeConsumer(storeConfig);
            if (consumerInitResult is error) {
                log:printError("Error while re-connecting to queue "
                + storeConfig.queueName + " retry count = " + retryCount, err = consumerInitResult);
                retryCount = retryCount + 1;
                int retryDelay = retryInterval + math:round(retryCount * retryInterval *
                storeConfig.retryConfig.backOffFactor);
                if (retryDelay > maxRetryDelay) {
                    retryDelay = maxRetryDelay;
                }
                runtime:sleep(retryDelay * 1000);
            } else {
                log:printInfo("Successfuly re-connected to message broker queue = " + processorConfig.storeConfig.queueName);
                (self.jmsConnection, self.jmsSession, self.queueReceiver) = consumerInitResult;
                break;
            }
        }
        if(retryCount >= maxRetryCount && maxRetryCount != -1) {
            log:printError("Could not connect to message broker. Maximum retry count exceeded. Count = " + maxRetryCount
                       + ". Giving up retrying.");
        }
    }
};

# Initialize JMS consumer.   
#
# + storeConfig - `MessageStoreConfiguration` configuration 
# + return      - `jms:Connection, jms:Session, jms:QueueReceiver` created JMS connection, session and queue receiver if
#                  created successfully or error in case of an issue when initializing. 
function initializeConsumer(MessageStoreConfiguration storeConfig) returns
 (jms:Connection, jms:Session, jms:QueueReceiver) | error {

    string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);
    string acknowledgementMode = "CLIENT_ACKNOWLEDGE";
    string queueName = storeConfig.queueName;

    // This initializes a JMS connection with the provider.
    jms:Connection jmsConnection = new({
        initialContextFactory: initialContextFactory,
        providerUrl: storeConfig.providerUrl});

    // This initializes a JMS session on top of the created connection.
    jms:Session jmsSession = new(jmsConnection, {
            acknowledgementMode: acknowledgementMode
        });

    // This initializes a queue receiver.
    jms:QueueReceiver queueReceiver = new(jmsSession, queueName = queueName);

    (jms:Connection, jms:Session, jms:QueueReceiver) brokerConnection = (jmsConnection, jmsSession, queueReceiver);

    return brokerConnection;
}

# Get a function pointer with logic of when polling of messages met with an error. 
#
# + processor -  `MessageForwardingProcessor` in which queue consumer should be reset 
# + return    -  A function pointer with logic that close existing queue consumer of 
#                the given processor and re-init another consumer.         
function onMessagePollingFail(MessageForwardingProcessor processor) returns function() {
    return function () {
        log:printInfo("onMessagePollingFail is CALLED!!");
        var cleanupResult = processor.cleanUpJMSObjects();
        if (cleanupResult is error) {
            log:printError("Error while cleaning up jms connection", err = cleanupResult);
        }
        processor.retryToConnectBroker(processor.processorConfig);
    };
}

# Get a function pointer with logic of deactivating message processor.
#
# + processor - message processor to deactivate
# + return - A function pointer with logic that deactivates message processor
function onDeactivate(MessageForwardingProcessor processor) returns function() {
    return function () {
        log:printInfo("Deactivating message processor on queue = " + processor.getQueueName());
        var processorStopResult = processor.stop();
        if (processorStopResult is error) {
            log:printError("Error when stopping message polling task", err = processorStopResult);
        }
    };

}


# Configuration for Message-forwarding-processor. 
#
# + storeConfig - Config containing store information `MessageStoreConfiguration`  
# + HttpEndpointUrl - Messages will be forwarded to this HTTP url
# + HttpOperation - HTTP Verb to use when forwarding the message
# + HttpEndpointConfig - `ClientEndpointConfig` HTTP client config to use when forwarding messages to HTTP endpoint
# + pollTimeConfig - Interval messages should be polled from the 
#                    broker (Milliseconds) or cron expression for polling task  
# + retryInterval - Interval messages should be re-tried in case of forwading failure (Milliseconds) 
# + retryHttpStatusCodes - If processor received any response after forwading the message with any of 
#                          these status codes, it will be considered as a failed invocation `int[]` 
# + maxRedeliveryAttempts - Max number of times a message should be re-tried in case of forwading failure 
# + forwardingFailAction - Action to take when a message is failed to forward. `MessageForwardFailAction`
#                          `DROP` - drop message and continue (default)
#                          `DLC_STORE`- store message in configured  `DLCStore`
#                          `DEACTIVATE` - stop message processor                           
# + batchSize - Maximum number of messages to forward upon message process task is executed 
# + forwardingInterval - Time in milliseconds between two message forwards in a batch
# + DLCStore - In case of forwarding failure, messages will be stored using this backup `Client`. Make sure `forwardingFailAction` is
#              `DLC_STORE`
public type ForwardingProcessorConfiguration record {|
    MessageStoreConfiguration storeConfig;
    string HttpEndpointUrl;
    http:HttpOperation HttpOperation = http:HTTP_POST;
    http:ClientEndpointConfig? HttpEndpointConfig = ();

    //configured in milliseconds for polling interval
    //can specify a cron instead
    int|string pollTimeConfig;

    //forwarding retry
    int retryInterval;    //configured in milliseconds
    int[] retryHttpStatusCodes?;
    int maxRedeliveryAttempts;  

    //action on forwarding fail of a message
    MessageForwardFailAction forwardingFailAction = DROP;

    //batching messages for forwarding
    int batchSize = 1;
    int forwardingInterval = 0;

    //specify message store client to forward failing messages
    Client DLCStore?;
|};

# Record passing required information to service attached to message processor task.
#
# + queueReceiver - `jms:QueueReceiver` receiver to use when polling messages  
# + queueName - Name of the queue to receive messages from  
# + httpClient - `http:Client` http client used to forward messages 
# + httpEP - Messages will be forwarded to this HTTP url 
# + HttpOperation - HTTP Verb to use when forwarding the message
# + DLCStore - In case of forwarding failure, messages will be stored using this backup `Client`
# + forwardingFailAction - `MessageForwardFailAction` specifing processor behaviour on fowarding failure 
# + retryHttpCodes - If processor received any response after forwading the message with any of
#                    these status codes, it will be considered as a failed invocation `int[]` 
# + batchSize - Maximum number of messages to forward upon message process task is executed 
# + forwardingInterval - Time in milliseconds between two message forwards in a batch
# + onMessagePollingFail - Lamda with logic what to execute on a failure polling messages from broker `function()`
# + onDeactivate - Lamda with logic what to execute to deactivate message processor  
# + preProcessRequest - Lamda to execute upon request which is stored, before forwarding to the configured endpoint
# + handleResponse - Lamda to execute upon response received by forwarding messages to the configured endpoint 
#                    `function(http:Response resp)`
type PollingServiceConfig record {
    jms:QueueReceiver queueReceiver;
    string queueName;
    http:Client httpClient;
    string httpEP;
    http:HttpOperation HttpOperation;
    Client? DLCStore;
    MessageForwardFailAction forwardingFailAction;
    int[] retryHttpCodes;
    int batchSize;
    int forwardingInterval;
    function() onMessagePollingFail;
    function() onDeactivate;
    function(http:Request request)? preProcessRequest;
    function(http:Response resp) handleResponse;
};

