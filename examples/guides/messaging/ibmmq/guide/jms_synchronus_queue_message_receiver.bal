// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jms;
import ballerina/log;

// Initialize a JMS connection with the provider.
jms:Connection jmsConnection = new({
    initialContextFactory: "com.sun.jndi.fscontext.RefFSContextFactory",
    providerUrl: "file:/jndidirectory/",
    connectionFactoryName: "QueueConnectionFactory",
    username: "",
    password: ""
});

// Initialize a JMS session on top of the created connection.
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session.
listener jms:QueueReceiver queueReceiver = new(jmsSession, queueName = "Queue");

public function main() {
    jms:QueueReceiverCaller caller = queueReceiver.getCallerActions();
    var result = caller->receive(timeoutInMilliSeconds = 5000);

    if (result is jms:Message) {
        var messageText = result.getTextMessageContent();
        if (messageText is string) {
            log:printInfo("Message : " + messageText);
        } else {
            log:printError("Error occurred while reading message.",
                err = messageText);
        }
    } else if (result is ()) {

        log:printInfo("Message not received");

    } else {
        log:printInfo("Error receiving message : " +
                <string>result.detail().message);
    }
}
