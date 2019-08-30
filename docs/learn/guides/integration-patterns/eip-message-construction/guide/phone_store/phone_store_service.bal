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

// Deploying on kubernetes.

//import ballerinax /kubernetes;

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

// Deploying on docker.

//import ballerinax /docker;

// Type definition for a phone order.
//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "phone_store_service",
//    tag: "v1.0",
//    baseImage: "ballerina/ballerina-platform:0.980.0"
//}

//@docker:Expose {}

// Type definition for a phone order.
type PhoneOrder record {
    string customerName?;
    string address?;
    string contactNumber?;
    string orderedPhoneName?;
};

// Global variable containing all the available phones.
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// Initialize a JMS connection with the provider.
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use.
// 'Apache ActiveMQ' has been used as the message broker in this example.
jms:Connection orderQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session orderQueueJmsSessionSend = new(orderQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session.
jms:QueueSender jmsProducerOrderQueue = new(orderQueueJmsSessionSend, queueName = "OrderQueue");

// Service endpoint.
listener http:Listener httpListener = new(9090);

http:Request backendreq = new;

// Phone store service, which allows users to order phones online for delivery.
@http:ServiceConfig {
    basePath: "/phonestore"
}
service phoneStoreService on httpListener {
    // Resource that allows users to place an order for a phone.
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        backendreq = untaint request;
        http:Response response = new;
        PhoneOrder newOrder = {};
        json requestPayload = {};

        var payload = request.getJsonPayload();
        // Try parsing the JSON payload from the request.
        if (payload is json) {
            // Valid JSON payload.
            requestPayload = payload;
        } else {
            // NOT a valid JSON payload.
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            checkpanic caller->respond(response);
            return;
        }

        json name = requestPayload.Name;
        json address = requestPayload.Address;
        json contact = requestPayload.ContactNumber;
        json phoneName = requestPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            checkpanic caller->respond(response);
            return;
        }

        // Order details.
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // Boolean variable to track the availability of a requested phone.
        boolean isPhoneAvailable = false;
        // Check the availability of the requested phone.
        foreach var phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'.
        if (isPhoneAvailable) {
            var phoneOrderDetails = json.convert(newOrder);

            if(phoneOrderDetails is json) {
                // Create a JMS message.
                var queueMessage = orderQueueJmsSessionSend.createTextMessage(phoneOrderDetails.toString());

                if (queueMessage is jms:Message) {
                    log:printInfo("order will be added to the order  Queue; CustomerName: '" + newOrder.customerName +
                            "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");

                    // Send the message to the JMS queue.
                    checkpanic jmsProducerOrderQueue->send(queueMessage);

                    // Construct a success message for the response.
                    responseMessage = { "Message":
                    "Your order was successfully placed. Ordered phone will be delivered soon" };
                } else {
                    responseMessage = { "Message": "Error while creating the message" };
                }
            } else {
                responseMessage = { "Message": "Invalid order delivery details" };
            }
        }
        else {
            // If phone is not available, construct a proper response message to notify user.
            responseMessage = { "Message": "Requested phone not available" };
        }

        // Send response to the user.
        response.setJsonPayload(responseMessage);
        checkpanic caller->respond(response);
    }
    // Resource that allows users to get a list of all the available phones.
    @http:ResourceConfig { methods: ["GET"], produces: ["application/json"] }
    resource function getPhoneList(http:Caller httpClient, http:Request request) {
        http:Response response = new;
        // Send json array 'phoneInventory' as the response, which contains all the available phones.
        response.setJsonPayload(phoneInventory);
        checkpanic httpClient->respond(response);
    }
}

jms:Connection orderQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session orderQueueJmsSessionReceive = new(orderQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session.
listener jms:QueueReceiver jmsConsumerOrderQueue = new(orderQueueJmsSessionReceive, queueName = "OrderQueue");

// JMS service that consumes messages from the JMS queue.
// Bind the created consumer to the listener service.
service orderDeliverySystem on jmsConsumerOrderQueue {

    // Triggered whenever an order is added to the 'OrderQueue'.
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New order successfilly received from the Order Queue");

        // Retrieve the string payload using native function.
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Order Details: " + stringPayload);
        }

        // Send order queue details to delivery queue.
        http:Request enrichedreq = backendreq;
        var clientResponse = phoneOrderDeliveryServiceEP->forward("/", enrichedreq);
        if (clientResponse is http:Response) {
            log:printInfo("Order details were sent to phone_order_delivery_service.");
        } else {
            log:printError("Order details were not sent to phone_order_delivery_service.");
        }
    }
}
http:Client phoneOrderDeliveryServiceEP = new("http://localhost:9091/deliveryDetails/sendDelivery");
