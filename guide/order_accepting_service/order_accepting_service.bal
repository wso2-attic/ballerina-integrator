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
import ballerinax/docker;

// Type definition for a order
type Order record {
    string customerID;
    string productID;
    string quantity;
    string orderType;
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
endpoint jms:QueueSender jmsProducer {
    session: jmsSession,
    queueName: "Order_Queue"
};


//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "order_accepting_service.bal",
//    tag: "v1.0"
//}

//@docker:CopyFiles {
//    files: [{ source: "/home/krishan/Servers/apache-activemq-5.12.0/lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar",
//        target: "/ballerina/runtime/bre/lib" }, { source:
//    "/home/krishan/Servers/apache-activemq-5.12.0/lib/activemq-client-5.12.0.jar",
//        target: "/ballerina/runtime/bre/lib" }] }

//@docker:Expose {}
//endpoint http:Listener listener {
//    port: 9090
//};

// Order Accepting Service, which allows users to place order online
@http:ServiceConfig { basePath: "/placeOrder" }
service<http:Service> orderAcceptingService bind listener {
    // Resource that allows users to place an order 
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    place(endpoint caller, http:Request request) {
        http:Response response;
        Order newOrder;
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
                _ = caller->respond(response);
                done;
            }
        }

        json customerID = reqPayload.customerID;
        json productID = reqPayload.productID;
        json quantity = reqPayload.quantity;
        json orderType = reqPayload.orderType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (customerID == null || productID == null || quantity == null || orderType == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = caller->respond(response);
            done;
        }

        // Order details
        newOrder.customerID = customerID.toString();
        newOrder.productID = productID.toString();
        newOrder.quantity = quantity.toString();
        newOrder.orderType = orderType.toString();

        json responseMessage;
        var orderDetails = check <json>newOrder;
        // Create a JMS message
        jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails.toString());
        // Send the message to the JMS queue
        _ = jmsProducer->send(queueMessage);
        // Construct a success message for the response
        responseMessage = { "Message": "Your order is successfully placed" };
        log:printInfo("New order added to the JMS Queue; customerID: '" + newOrder.customerID +
                "', productID: '" + newOrder.productID + "';");

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller->respond(response);
    }
}
