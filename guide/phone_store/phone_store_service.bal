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

import ballerina/http;
import ballerina/jms;
import ballerina/log;

//Deploying on kubernetes

//import ballerinax /kubernetes;

//Type definition for a phone order
//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
//'jms:Connection' definition
//'jms:Session' definition
//'jms:QueueSender' endpoint definition

//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-phone_store_service",
//    path: "/"
//}

//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-phone_store_service"
//}

//@kubernetes:Deployment {
//    image: "ballerina.guides.io/phone_store_service:v1.0",
//    name: "ballerina-guides-phone_store_service"
//}

//Deploying on docker

//import ballerinax /docker;

//Type definition for a phone order
//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
//'jms:Connection' definition
//'jms:Session' definition
//'jms:QueueSender' endpoint definition

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "phone_store_service",
//    tag: "v1.0",
//    baseImage: "ballerina/ballerina-platform:0.980.0"
//}

//Service endpoint
//@docker:Expose {}

// Type definition for a phone order
type PhoneOrder record {
    string customerName;
    string address;
    string contactNumber;
    string orderedPhoneName;
};

// Global variable containing all the available phones
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection orderQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a JMS session on top of the created connection
jms:Session orderQueueJmsSessionSend = new(orderQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducerOrderQueue {
    session: orderQueueJmsSessionSend,
    queueName: "OrderQueue"
};
// Service endpoint
endpoint http:Listener listener {
    port: 9090
};

//backendreq used to obtain details of order queue
public http:Request backendreq;

// phone store service, which allows users to order phones online for delivery
@http:ServiceConfig { basePath: "/phonestore" }
service<http:Service> phoneStoreService bind listener {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    placeOrder(endpoint caller, http:Request request) {

        backendreq = untaint request;
        http:Response response;
        PhoneOrder newOrder;
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
        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = caller->respond(response);
            done;
        }
        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneOrderDetails = check <json>newOrder;
            // Create a JMS message
            jms:Message queueMessage = check orderQueueJmsSessionSend.createTextMessage(phoneOrderDetails.toString());

            log:printInfo("order will be added to the order  Queue; CustomerName: '" + newOrder.customerName +
                    "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");

            // Send the message to the JMS queue
            _ = jmsProducerOrderQueue->send(queueMessage);

            // Construct a success message for the response
            responseMessage = { "Message": "Your order was successfully placed. Ordered phone will be delivered soon" };
        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = { "Message": "Requested phone not available" };
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller->respond(response);
    }
    // Resource that allows users to get a list of all the available phones
    @http:ResourceConfig { methods: ["GET"], produces: ["application/json"] }
    getPhoneList(endpoint client, http:Request request) {
        http:Response response;
        // Send json array 'phoneInventory' as the response, which contains all the available phones
        response.setJsonPayload(phoneInventory);
        _ = client->respond(response);
    }
}
jms:Connection orderQueueJmsConnectionRecieve = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session orderQueueJmsSessionRecieve = new(orderQueueJmsConnectionRecieve, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumerOrderQueue {
    session: orderQueueJmsSessionRecieve,
    queueName: "OrderQueue"
};
// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDeliverySystem bind jmsConsumerOrderQueue {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message) {
        log:printInfo("New order successfilly received from the Order Queue");
        // Retrieve the string payload using native function
        string stringPayload = check message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);

        //send order queue details to delivery queue
        http:Request enrichedreq = backendreq;
        var clientResponse = phoneOrderDeliveryServiceEP->forward("/", enrichedreq);
        match clientResponse {
            http:Response res => {
                log:printInfo("Order details were sent to phone_order_delivery_service.");
            }
            error err => {
                log:printError("Order details were not sent to phone_order_delivery_service.");
            }
        }
    }
}
endpoint http:Client phoneOrderDeliveryServiceEP {
    url: "http://localhost:9091/deliveryDetails/sendDelivery"
};
