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
import ballerina/io;

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

// Initialize a queue receiver using the created session
listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "Order_Queue");

// Initialize a retail queue sender using the created session
jms:QueueSender jmsProducerRetail = new(jmsSession, queueName = "Retail_Queue");

// Initialize a wholesale queue sender using the created session
jms:QueueSender jmsProducerWholesale = new(jmsSession, queueName = "Wholesale_Queue");

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service orderDispatcherService on jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) returns error? {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = message.getTextMessageContent();
        if (orderDetails is string) {
            log:printInfo("validating  Details: " + orderDetails);
            //Converting String content to JSON
            io:StringReader reader = new io:StringReader(orderDetails);
            var result = reader.readJson();
            var closeResult = reader.close();

            if (result is json) {
                //Retrieving JSON attribute "OrderType" value
                json orderType = result.orderType;
                //filtering and routing messages using message orderType
                if (orderType.toString() == "retail") {
                    // Create a JMS message
                    var queueMessage = jmsSession.createTextMessage(orderDetails);
                    if (queueMessage is jms:Message) {
                        // Send the message to the Retail JMS queue
                        _ = check jmsProducerRetail->send(queueMessage);
                        log:printInfo("New Retail order added to the Retail JMS Queue");
                    } else {
                        log:printError("Error while adding the retail order to the JMS queue");
                    }
                } else if (orderType.toString() == "wholesale"){
                    // Create a JMS message
                    var queueMessage = jmsSession.createTextMessage(orderDetails);
                    if (queueMessage is jms:Message) {
                        // Send the message to the Wolesale JMS queue
                        _ = check jmsProducerWholesale->send(queueMessage);
                        log:printInfo("New Wholesale order added to the Wholesale JMS Queue");
                    } else {
                        log:printError("Error while adding the wholesale order to the JMS queue");
                    }
                } else {
                    //ignoring invalid orderTypes
                    log:printInfo("No any valid order type recieved, ignoring the message, order type recieved - " +
                            orderType.toString());
                }
            } else {
                log:printError("Error occured while processing the order");
            }
        } else {
            log:printError("Invalid order details, error occured while processing the order");
        }
    }
}
