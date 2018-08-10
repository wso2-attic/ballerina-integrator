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
endpoint jms:QueueReceiver jmsConsumer {
    session:jmsSession,
    queueName:"Order_Queue"
};

// Initialize a retail queue sender using the created session
endpoint jms:QueueSender jmsProducerRetail {
    session:jmsSession,
    queueName:"Retail_Queue"
};

// Initialize a wholesale queue sender using the created session
endpoint jms:QueueSender jmsProducerWholesale {
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
        log:printInfo("validating  Details: " + orderDetails);
        //Converting String content to JSON
        io:StringReader reader = new io:StringReader(orderDetails);
        json result = check reader.readJson();
        var closeResult = reader.close();
        //Retrieving JSON attribute "OrderType" value
        json orderType = result.orderType;
        //filtering and routing messages using message orderType
        if(orderType.toString() == "retail"){
              // Create a JMS message
                jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails);
            // Send the message to the Retail JMS queue
             _ = jmsProducerRetail -> send(queueMessage);
             log:printInfo("New Retail order added to the Retail JMS Queue");
        }else if(orderType.toString() == "wholesale"){
            // Create a JMS message
                jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails);
            // Send the message to the Wolesale JMS queue
             _ = jmsProducerWholesale -> send(queueMessage);
             log:printInfo("New Wholesale order added to the Wholesale JMS Queue");
        }else{    
            //ignoring invalid orderTypes  
        log:printInfo("No any valid order type recieved, ignoring the message, order type recieved - " + orderType.toString());
        }    
    }
}