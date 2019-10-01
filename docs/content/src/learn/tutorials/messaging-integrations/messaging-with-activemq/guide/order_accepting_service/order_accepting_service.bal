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
import ballerina/http;
import ballerina/jms;

// Type definition for an order
type Order record {
    string customerID?;
    string productID?;
    string quantity?;
    string orderType?;
};

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session
jms:QueueSender jmsProducer = new(jmsSession, queueName = "Order_Queue");

//export http listner port on 9090
listener http:Listener httpListener = new(9090);

// Order Accepting Service, which allows users to place order online
@http:ServiceConfig { basePath: "/placeOrder" }
service orderAcceptingService on httpListener {
    // Resource that allows users to place an order 
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    resource function place(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        Order newOrder = {};
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            reqPayload = payload;
        } else {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            _ = check caller->respond(response);
            return;
        }

        json customerID = reqPayload.customerID;
        json productID = reqPayload.productID;
        json quantity = reqPayload.quantity;
        json orderType = reqPayload.orderType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (customerID == null || productID == null || quantity == null || orderType == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = check caller->respond(response);
            return;
        }

        // Order details
        newOrder.customerID = customerID.toString();
        newOrder.productID = productID.toString();
        newOrder.quantity = quantity.toString();
        newOrder.orderType = orderType.toString();

        json responseMessage;
        var orderDetails = json.convert(newOrder);
        // Create a JMS message
        if (orderDetails is json) {
            var queueMessage = jmsSession.createTextMessage(orderDetails.toString());
            // Send the message to the JMS queue
            if (queueMessage is jms:Message) {
                _ = check jmsProducer->send(queueMessage);
                // Construct a success message for the response
                responseMessage = { "Message": "Your order is successfully placed" };
                log:printInfo("New order added to the JMS queue; customerID: '" + newOrder.customerID +
                        "', productID: '" + newOrder.productID + "';");
            } else {
                responseMessage = { "Message": "Error occured while placing the order" };
                log:printError("Error occured while adding the order to the JMS queue");
            }
        } else {
            responseMessage = { "Message": "Error occured while placing the order" };
            log:printError("Error occured while placing the order");
        }
        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = check caller->respond(response);
    }
}
