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


# Definition of forwarding Processor object. It polls messages from Message Broker
# pointed and forwards messages to the configred HTTP endpoint with reliability. 
public type MessageForwardingProcessor object {

    ForwardingProcessorConfiguration processorConfig;

    //objects related to JMS connection
    jms:Connection jmsConnection;
    jms:Session jmsSession;
    jms:QueueReceiver queueReceiver;

    //HTTP client used to forward messages to HTTP endpoint
    http:Client httpClient;

    //task driving the message polling from the broker and forward
    task:Scheduler messageForwardingTask;

    //constructor for ForwardingProcessor

    # Initialize `MessageForwardingProcessor` object. This will create necessary
    # connnections to the configured message broker and configured backend. Polling 
    # of messages is not started until `start` is called. 
    # 
    # + processorConfig - `ForwardingProcessorConfiguration` processor configuration 
    # + handleResponse  - `function (http:Response resp)` lamda to process the response from HTTP BE 
    #                      after forwarding the request by processor
    # + return          - `error` if there is an issue initializing processor (i.e connection issue with broker)
    public function __init(ForwardingProcessorConfiguration processorConfig,
    function(http:Response resp) handleResponse) returns error? {

        self.processorConfig = processorConfig;

        MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);
        string acknowledgementMode = "CLIENT_ACKNOWLEDGE";
        string queueName = storeConfig.queueName;

        //init connection to the broker
        var consumerInitResult = check initializeConsumer(storeConfig);
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


        //create a record with objects needed by the polling service
        PollingServiceConfig pollingServiceConfig = {
            queueReceiver: self.queueReceiver,
            queueName: queueName,
            httpClient: self.httpClient,
            httpEP: processorConfig.HTTPEndpoint,
            deactivateOnFail: processorConfig.deactivateOnFail,
            onMessagePollingFail: onMessagePollingFail(self),
            handleResponse: handleResponse
        };

        Client? dlcStore = processorConfig["DLCStore"];
        if (dlcStore is Client) {
            pollingServiceConfig.DLCStore = dlcStore;
        }

        int[]? retryHTTPCodes = processorConfig["retryHTTPStatusCodes"];
        if (retryHTTPCodes is int[]) {
            pollingServiceConfig.retryHTTPCodes = retryHTTPCodes;
        }

        //attach the task work
        var assignmentResult = self.messageForwardingTask.attach(messageForwardingService,  attachment = pollingServiceConfig);
        if (assignmentResult is error) {
            log:printError("Error when attaching service to the message processor task ", err = assignmentResult);
            return assignmentResult;
        }
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
    }


    # Initialize HTTP client to forward messages.
    #
    # + processorConfig - `ForwardingProcessorConfiguration` config 
    # + return - `http:Client` in case of successful initialization or `error` in case of issue
    function initializeHTTPClient(ForwardingProcessorConfiguration processorConfig) returns http:Client | error {
        http:Client backendClientEP = new(processorConfig.HTTPEndpoint, config = {

            retryConfig: {
                interval: processorConfig.retryInterval, //Retry interval in milliseconds
                count: processorConfig.maxRedeliveryAttempts,   //Number of retry attempts before giving up
                backOffFactor: 1.0, //Multiplier of the retry interval
                maxWaitInterval: 20000,  //Maximum time of the retry interval in milliseconds
                statusCodes: processorConfig.retryHTTPStatusCodes //HTTP response status codes which are considered as failures
            },
            timeoutMillis: 2000
        });
        return backendClientEP;
    }

    # Clean up JMS objects (connections, sessions and consumers). 
    #
    # + return - `error` in case of stopping and closing JMS objects
    function cleanUpJMSObjects() returns error? {
        check self.queueReceiver.__stop();
        //TODO: Ballerina has no method to close session
        //TODO: Ballerina has no method to close connection
        self.jmsConnection.stop();
    }

    # Retry connecting to broker according to given config. This will try forever
    # until connection get successful.  
    function retryToConnectBroker(ForwardingProcessorConfiguration processorConfig) {
        MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
        int retryCount = 0;
        while (true) {
            var consumerInitResult = initializeConsumer(storeConfig);
            if (consumerInitResult is error) {
                log:printError("Error while re-connecting to queue "
                + storeConfig.queueName + " retry count = " + retryCount, err = consumerInitResult);
                retryCount = retryCount + 1;
                int retryDelay = math:round(processorConfig.storeConnectionAttemptInterval *
                processorConfig.storeConnectionBackOffFactor);
                if (retryDelay > processorConfig.maxStoreConnectionAttemptInterval) {
                    retryDelay = processorConfig.maxStoreConnectionAttemptInterval;
                }
                runtime:sleep(retryDelay * 1000);
            } else {
                (self.jmsConnection, self.jmsSession, self.queueReceiver) = consumerInitResult;
                break;
            }
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
            //TODO: we need stop the polling here?
        }
        processor.retryToConnectBroker(processor.processorConfig);
    };
}


# Configuration for Message-forwarding-processor 
#
# + storeConfig - Config containing store information `MessageStoreConfiguration`  
# + HTTPEndpoint - Messages will be forwarded to this HTTP url
# + pollTimeConfig - Interval messages should be polled from the 
#                    broker (Milliseconds) or cron expression for polling task  
# + retryInterval - Interval messages should be re-tried in case of forwading failure (Milliseconds) 
# + retryHTTPStatusCodes - If processor received any response after forwading the message with any of 
#                          these status codes, it will be considered as a failed invocation `int[]` 
# + maxRedeliveryAttempts - Max number of times a message should be re-tried in case of forwading failure 
# + maxStoreConnectionAttemptInterval - Max time interval to attempt connecting to broker (seconds)  
# + storeConnectionAttemptInterval -  Time interval to attempt connecting to broker (seconds). Each time this time
#                                     get multiplied by `storeConnectionBackOffFactor` until `maxStoreConnectionAttemptInterval`
#                                     is reached
# + storeConnectionBackOffFactor - Multiplier for interval to attempt connecting to broker
# + DLCStore - In case of forwarding failure, messages will be stored using this backup `Client`
# + deactivateOnFail - `true` if processor needs to be deactivated on fowarding failure 
public type ForwardingProcessorConfiguration record {
    MessageStoreConfiguration storeConfig;
    string HTTPEndpoint;

    //configured in milliseconds for polling interval
    //can specify a cron instead
    int | string pollTimeConfig;

    //forwarding retry
    int retryInterval;    //configured in milliseconds
    int[] retryHTTPStatusCodes?;
    int maxRedeliveryAttempts;

    //connection retry
    //TODO: make these optional with defaults
    int maxStoreConnectionAttemptInterval = 60;    //configured ins econds
    int storeConnectionAttemptInterval = 5;    //configured in seconds
    float storeConnectionBackOffFactor = 1.2;    //configured ins econds

    //specify message store client to forward failing messages
    Client DLCStore?;
    //specify if processor should deactivate on forwading failure
    boolean deactivateOnFail = false;

};

# Record passing required information to service attached to message processor task
#
# + queueReceiver - `jms:QueueReceiver` receiver to use when polling messages  
# + queueName - Name of the queue to receive messages from  
# + httpClient - `http:Client` http client used to forward messages 
# + httpEP - Messages will be forwarded to this HTTP url 
# + DLCStore - In case of forwarding failure, messages will be stored using this backup `Client`  
# + deactivateOnFail - `true` if processor needs to be deactivated on fowarding failure 
# + retryHTTPCodes - If processor received any response after forwading the message with any of
#                    these status codes, it will be considered as a failed invocation `int[]` 
# + onMessagePollingFail - Lamda with logic what to execute on a failure polling messages from broker `function()`  
# + handleResponse - Lamda to execute upon response received by forwarding messages to the configured endpoint 
#                    `function(http:Response resp)`
public type PollingServiceConfig record {
    jms:QueueReceiver queueReceiver;
    string queueName;
    http:Client httpClient;
    string httpEP;
    Client DLCStore?;
    boolean deactivateOnFail;
    int[] retryHTTPCodes?;
    function() onMessagePollingFail;
    function(http:Response resp) handleResponse;
};

