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
    Client? failoverStore;

    //message broker queue message store client send messages to
    string queueName;

    public function __init(MessageStoreConfiguration storeConfig, boolean enableGuranteedDelivery = false, Client? failoverStore = ()) returns error? {
        string providerUrl = storeConfig.providerUrl;
        self.queueName = storeConfig.queueName;
        self.failoverStore = failoverStore;
        
        string? userName = storeConfig["userName"];
        string? password = storeConfig["password"];

        string acknowledgementMode = "AUTO_ACKNOWLEDGE";
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);


        // This initializes a JMS connection with the provider.
        self.jmsConnection = new({
                initialContextFactory: initialContextFactory,
                providerUrl: providerUrl
            });

        // This initializes a JMS session on top of the created connection.
        self.jmsSession = new(self.jmsConnection, {
                acknowledgementMode: acknowledgementMode
            });

        // This initializes a queue sender.
        self.queueSender = new(self.jmsSession, queueName = self.queueName);
    }

    # Store HTTP request. 
    # 
    # + request - HTTP request to store 
    # + return - `error` if there is an issue storing the message (i.e connection issue with broker)
    public remote function store(http:Request request) returns error? {
        map<string> requestMessageMap = {};
        string [] httpHeaders = request.getHeaderNames();
        foreach var headerName in httpHeaders {
            requestMessageMap[headerName] = request.getHeader(untaint headerName);
        }
        //set payload as an entry to the map message
        string payloadAsText = check request.getTextPayload();
        requestMessageMap[PAYLOAD] =  payloadAsText;
        
        //create a map message from message detail extracted 
        var messageToStore = self.jmsSession.createMapMessage(requestMessageMap);

        if (messageToStore is jms:Message) {
            // This sends the Ballerina message to the JMS provider.
            var returnVal = self.queueSender->send(messageToStore);
            if (returnVal is error) {
                //TODO: try to send to failover store if defined 
                string errorMessage = "Error occurred while sending the message to the queue " + self.queueName;
                log:printError(errorMessage);
                Client? failoverClient = self.failoverStore;
                //try failover store
                if(failoverClient is Client) {
                    check failoverClient->store(request);
                //return error(MESSAGE_STORE_ERROR_CODE,{ message:errorMessage});
                }
            }
        }
    }
};

# Configuration for Message Store 
#
# + messageBroker - Message broker store is connecting to 
# + providerUrl - connection url pointing to message broker 
# + queueName - messages will be stored to this queue on the broker  
# + userName - userName to use when connecting to the broker
# + password - password to use when connecting to the broker
public type MessageStoreConfiguration record {
    MessageBroker messageBroker;
    string providerUrl;
    string queueName;
    string userName?;
    string password?;
};

