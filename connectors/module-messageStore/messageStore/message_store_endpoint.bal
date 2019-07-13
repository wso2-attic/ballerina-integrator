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
import ballerina/http;
import ballerina/log;

# Connector client for storing messages on a message broker. Internally it uses 
# JMS connecor 
public type Client client object {

    //JMS connection related objects
    jms:Connection jmsConnection;
    jms:Session jmsSession;
    jms:QueueSender queueSender;

    //Message store client to use in case of fail to send by primary store client
    Client? secondaryStore;

    //sote client config
    MessageStoreConfiguration storeConfig;

    //message broker queue message store client send messages to
    string queueName;

    # Intiliazes MessageStore client. 
    # 
    # + storeConfig - `MessageStoreConfiguration` containing configurations
    # + return - `error` if there is an issue initlaizing connection to configured broker
    public function __init(MessageStoreConfiguration storeConfig) returns error? {
        self.storeConfig = storeConfig;
        self.queueName = storeConfig.queueName;
        self.secondaryStore = storeConfig["secondaryStore"];
        (self.jmsConnection, self.jmsSession, self.queueSender) = check self.intializeMessageSender(storeConfig);
    }

    # Store HTTP message. This has receliency for the delivery of the message to the message broker queue 
    # accroding to `MessageStoreRetryConfig`. Will return an `error` of all reries are elapsed, and if all retries 
    # configured to secondary message store are elapsed (if one specified)
    # 
    # + message - HTTP message to store 
    # + return - `error` if there is an issue storing the message (i.e connection issue with broker) 
    public remote function store(http:Request message) returns error? {
        map<any> requestMessageMap = {};
        string[] httpHeaders = message.getHeaderNames();
        foreach var headerName in httpHeaders {
            requestMessageMap[headerName] = message.getHeader(untaint headerName);
        }
        //set payload as an entry to the map message
        byte[] binaryPayload = check message.getBinaryPayload(); 
        requestMessageMap[PAYLOAD] = binaryPayload;
    
        var storeSendResult = self.tryToSendMessage(requestMessageMap);

        if (storeSendResult is error) {
            if (self.storeConfig.retryConfig == ()) {    //no resiliency, give up
                return storeSendResult;
            } else {
                MessageStoreRetryConfig retryConfig = self.storeConfig.retryConfig;
                int retryCount = 0;
                while (retryCount < retryConfig.count) {
                    log:printWarn("Error while sending message to queue " + self.queueName
                    + ". Retrying to send.  Retry count = " + (retryCount + 1));
                    boolean reTrySuccessful = true;
                    var reInitClientResult = self.reInitializeClient(self.storeConfig);
                    if (reInitClientResult is error) {
                        log:printError("Error while re-initializing store client to queue"
                        + self.queueName, err = reInitClientResult);
                        reTrySuccessful = false;
                    } else {
                        var storeResult = self.tryToSendMessage(requestMessageMap);
                        if (storeResult is error) {
                            log:printError("Error while trying to store message to queue"
                            + self.queueName, err = storeResult);
                            reTrySuccessful = false;
                        } else {
                            //send successful
                            break;
                        }
                    }
                    if (!reTrySuccessful) {
                        int retryDelay = retryConfig.interval
                        + math:round(retryCount * retryConfig.interval * retryConfig.backOffFactor);
                        if (retryDelay > retryConfig.maxWaitInterval) {
                            retryDelay = retryConfig.maxWaitInterval;
                        }
                        runtime:sleep(retryDelay * 1000);
                        retryCount = retryCount + 1;
                    }
                }
                log:printError("Maximum retries to store message breached queue = " + self.queueName);
                //if max retries breached. Check for failover store
                if (retryCount >= retryConfig.count) {
                    Client? failoverClient = self.secondaryStore;
                    //try failover store
                    if (failoverClient is Client) {
                        log:printInfo("Trying to store message in secondary configured for message store queue = " 
                            + self.queueName);
                        var failOverClientStoreResult = failoverClient->store(message);
                        if (failOverClientStoreResult is error) {
                            return failOverClientStoreResult;
                        }
                    } else {
                        //if no failover store, return original store error
                        return storeSendResult;
                    }
                }
            }
        }
    }


    # Try to deliver the message to message broker queue.  
    #
    # + requestMessageMap - Map representation `map<string>` of the message to store  
    # + return - `error` in case of an issue delivering the message to the queue
    function tryToSendMessage(map<any> requestMessageMap) returns error? {
        //create a map message from message detail extracted
        //TODO: here if error occurs it is not returned as an error. Ballerina should be fixed. (/ballerina-lang/issues/16099)
        var messageToStore = self.jmsSession.createMapMessage(requestMessageMap);
        if (messageToStore is jms:Message) {
            // This sends the Ballerina message to the JMS provider.
            var returnVal = self.queueSender->send(messageToStore);
            if (returnVal is error) {
                return returnVal;
            }
        } else {
            return messageToStore;
        }
    }

    
    # Intialize connection, session and sender to the message broker. 
    #
    # + storeConfig -  `MessageStoreConfiguration` config of message store 
    # + return - Created JMS objects as `(jms:Connection, jms:Session, jms:QueueSender)` or an `error` in case of issue  
    function intializeMessageSender(MessageStoreConfiguration storeConfig) returns (jms:Connection, jms:Session, jms:QueueSender)|error {

        string providerUrl = storeConfig.providerUrl;
        self.queueName = storeConfig.queueName;

        //TODO: JMS connector need to use these for security (/ballerina-lang/issues/16507). Currenlty, no usage. 
        string? userName = storeConfig["userName"];
        string? password = storeConfig["password"];

        string acknowledgementMode = "AUTO_ACKNOWLEDGE";
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);

        // This initializes a JMS connection with the provider.
        jms:Connection jmsConnection = new({
                initialContextFactory: initialContextFactory,
                providerUrl: providerUrl
            });

        // This initializes a JMS session on top of the created connection.
        jms:Session jmsSession = new(jmsConnection, {
                acknowledgementMode: acknowledgementMode
            });

        // This initializes a queue sender.
        jms:QueueSender queueSender = new(jmsSession, queueName = self.queueName);

        return (jmsConnection, jmsSession, queueSender);
    }


    # Close message sender and related JMS connections. 
    #
    # + return - `error` in case of closing 
    function closeMessageSender() returns error? {
        //TODO: implement these methods (/ballerina-lang/issues/16508)
        //self.queueSender.stop(); 
        //self.jmsSession.close();
        self.jmsConnection.stop();
    }


    # Reinitialiaze Message Store client. 
    # 
    # + storeConfig - Configuration to initialize message store 
    # + return - `error` in case of initalization issue (i.e connection to broker could not established)
    function reInitializeClient(MessageStoreConfiguration storeConfig) returns error? {
        check self.closeMessageSender();
        (self.jmsConnection, self.jmsSession, self.queueSender) = check self.intializeMessageSender(storeConfig); 
    }
};

# Configuration for Message Store.MessageForwardingProcessor 
#
# + messageBroker - Message broker store is connecting to 
# + secondaryStore - `Client` which is used to forward messages when primary store is not reachable 
# + retryConfig - `MessageStoreRetryConfig` related to recelliency of message store client (optional)
# + providerUrl - connection url pointing to message broker 
# + queueName - messages will be stored to this queue on the broker  
# + userName - userName to use when connecting to the broker (optional)
# + password - password to use when connecting to the broker (optional)
public type MessageStoreConfiguration record {|
    MessageBroker messageBroker;
    Client secondaryStore?;
    MessageStoreRetryConfig retryConfig?;
    string providerUrl;
    string queueName;
    string userName?;
    string password?;
|};

# Message Store retry configuration. Message store will retry to store a message 
# according to this config retrying to connect to message broker. In message processor 
# same config will be use to retry polling a message retrying to connect to the message broker. 
#
# + interval - Time interval to attempt connecting to broker (seconds). Each time this time
#              get multiplied by `backOffFactor` until `maxWaitInterval`
#              is reached
# + count - Number of retry attempts before giving up 
# + backOffFactor - Multiplier of the retry `interval` 
# + maxWaitInterval - Max time interval to attempt connecting to broker (seconds) and resend
public type MessageStoreRetryConfig record {|
    int interval = 5;
    int count;
    float backOffFactor = 1.5;
    int maxWaitInterval = 60;
|};
