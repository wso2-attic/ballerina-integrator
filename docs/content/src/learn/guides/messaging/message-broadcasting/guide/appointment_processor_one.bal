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
import ballerina/log;
import ballerina/http;
import ballerina/io;

// JMS listener listening on topic
listener jms:TopicSubscriber subscriberEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, topicPattern = "appointmentTopic");


service jmsListener on subscriberEndpoint {
    // Invoked upon JMS message receive
    resource function onMessage(jms:TopicSubscriberCaller consumer,
    jms:Message message) {
        // Receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json jsonMessage = checkpanic sr.readJson();
            // Write to database
            processMessage(jsonMessage);

        } else {
            log:printError("Error occurred while reading message " + messageText.reason());
        }
    }
}

function processMessage(json payload) {
    log:printInfo("service one received message: " + payload.toString());
}