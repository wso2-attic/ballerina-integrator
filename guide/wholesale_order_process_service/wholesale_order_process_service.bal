// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/jms;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a retail queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session:jmsSession,
    queueName:"Wholesale_Queue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDispatcherService bind jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    onMessage(endpoint consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = check message.getTextMessageContent();
        log:printInfo("below wholesale order has been successfully processed");
        log:printInfo(orderDetails);

    }
}