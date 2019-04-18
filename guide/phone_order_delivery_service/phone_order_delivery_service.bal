// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.

// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0

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
//import ballerinax/kubernetes;

//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-phone_order_delivery_service",
//    path: "/"
//}

//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-phone_order_delivery_service"
//}

//@kubernetes:Deployment {
//    image: "ballerina.guides.io/phone_store_service:v1.0",
//    name: "ballerina-guides-phone_order_delivery_service"
//}

// Deploying on docker.
//import ballerinax/docker;

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "phone_order_delivery_service",
//    tag: "v1.0",
//    baseImage: "ballerina/ballerina-platform:0.980.0"
//}

//@docker:Expose {}

type PhoneDeliver record {
    string customerName?;
    string address?;
    string contactNumber?;
    string deliveryPhoneName?;
};

json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

jms:Connection DeliveryQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session DeliveryQueueJmsSessionSend = new(DeliveryQueueJmsConnectionSend,
    { acknowledgementMode: "AUTO_ACKNOWLEDGE" });

// Initialize a queue sender using the created session.
jms:QueueSender jmsProducerDeliveryQueue = new(DeliveryQueueJmsSessionSend, queueName = "DeliveryQueue");


// Service endpoint.
listener http:Listener deliveryEP = new(9091);

@http:ServiceConfig {
    basePath: "/deliveryDetails"
}
// Phone store service, which allows users to order phones online for delivery.
service phoneOrderDeliveryService on deliveryEP {

    // Resource that allows users to place an order for a phone.
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function sendDelivery(http:Caller caller, http:Request request) {
        http:Response response = new;
        PhoneDeliver newDeliver = {};
        json requestPayload = {};

        log:printInfo("Received order details from the phone store service");

        // Try parsing the JSON payload from the request.
        var payload = request.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload.
            requestPayload = payload;
        } else {
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
            checkpanic caller-> respond(response);
            return;
        }

        // Order details.
        newDeliver.customerName = name.toString();
        newDeliver.address = address.toString();
        newDeliver.contactNumber = contact.toString();
        newDeliver.deliveryPhoneName = phoneName.toString();

        // Boolean variable to track the availability of a requested phone.
        boolean isPhoneAvailable = false;

        // Check the availability of the requested phone.
        foreach var phone in phoneInventory {
            if (newDeliver.deliveryPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage = {};

        // If the requested phone is available, then add the order to the 'OrderQueue'.
        if (isPhoneAvailable) {
            var phoneDeliverDetails = json.convert(newDeliver);
            // Create a JMS message.
            if (phoneDeliverDetails is json) {
                var queueMessage = DeliveryQueueJmsSessionSend.createTextMessage(phoneDeliverDetails.toString());
                if (queueMessage is jms:Message) {
                    log:printInfo("Order delivery details added to the delivery queue'; CustomerName: '" + newDeliver.
                            customerName +
                            "', OrderedPhone: '" + newDeliver.deliveryPhoneName + "';");
                    // Send the message to the JMS queue.
                    checkpanic jmsProducerDeliveryQueue-> send(queueMessage);

                    // Construct a success message for the response.
                    responseMessage =
                    { "Message": "Your order was successfully placed. Ordered phone will be delivered soon" };
                } else {
                    responseMessage =
                    { "Message": "Failed to place the order, Error while creating the message" };
                }
            } else {
                responseMessage =
                { "Message": "Failed to place the order, Invalid phone delivery details" };
            }
        }
        else {
            // If phone is not available, construct a proper response message to notify user.
            responseMessage = { "Message": "Requested phone not available" };
        }
        // Send response to the user
        response.setJsonPayload(responseMessage);
        checkpanic caller->respond(response);
    }
}
jms:Connection DeliveryQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session DeliveryQueueJmsSessionReceive = new(DeliveryQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session.
listener jms:QueueReceiver jmsConsumerDeliveryQueue = new(DeliveryQueueJmsSessionReceive, queueName = "DeliveryQueue");

service deliverySystem on jmsConsumerDeliveryQueue {

    // Triggered whenever an order is added to the 'OrderQueue'.
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New order successfully received from the delivery queue");

        // Retrieve the string payload using native function.
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Delivery details: " + stringPayload);
            log:printInfo("Delivery details sent to the customer successfully");
        } else {
            log:printError("Failed to retrieve the delivery details");
        }
    }
}
