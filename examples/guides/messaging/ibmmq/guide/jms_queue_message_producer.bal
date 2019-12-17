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
jms:QueueSender queueSender = new(jmsSession, queueName = "Queue");

public function main(string... args) {
    // Create a text message.
    var msg = jmsSession.createTextMessage("Hello from Ballerina");
    if (msg is error) {
        log:printError("Error occurred while creating message", err = msg);
    } else {
        var result = queueSender->send(msg);
        if (result is error) {
            log:printError("Error occurred while sending message", err = result);
        }
    }
}
