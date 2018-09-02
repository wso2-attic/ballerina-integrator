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

//import ballerinax/kubernetes;

// Type definition for a Deliver order
//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
// 'jms:Connection' definition
// 'jms:Session' definition
// 'jms:QueueSender' endpoint definition

//@kubernetes:Ingress {
//hostname:"ballerina.guides.io",
//name:"ballerina-guides-phone_order_delivery_service",
//path:"/"
//}

//@kubernetes:Service {
//serviceType:"NodePort",
//name:"ballerina-guides-phone_order_delivery_service"
//}

//@kubernetes:Deployment {
//image:"ballerina.guides.io/phone_store_service:v1.0",
//name:"ballerina-guides-phone_order_delivery_service"
//}

//endpoint http:Listener listener {
//port:9091
//};

//Deploying on docker

//import ballerinax/docker;

// Type definition for a  Deliver order
//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
// 'jms:Connection' definition
// 'jms:Session' definition
// 'jms:QueueSender' endpoint definition

//@docker:Config {
//registry:"ballerina.guides.io",
//name:"phone_order_delivery_service",
//tag:"v1.0",
//baseImage:"ballerina/ballerina-platform:0.980.0"
//}

// Service endpoint
//@docker:Expose{}

//endpoint http:Listener listener {
//port:9091
//};


type PhoneDeliver record {
    string customerName;
    string address;
    string contactNumber;
    string deliveryPhoneName;
};
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

jms:Connection DeliveryQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducerDeliveryQueue {
    session: DeliveryQueueJmsSessionSend,
    queueName: "DeliveryQueue"
};
// Initialize a JMS session on top of the created connection
jms:Session DeliveryQueueJmsSessionSend = new(DeliveryQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Service endpoint
endpoint http:Listener deliveryEP {
    port: 9091
};

@http:ServiceConfig { basePath: "/deliveryDetails" }
// phone store service, which allows users to order phones online for delivery
service<http:Service> phoneOrderDeliveryService bind deliveryEP {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    sendDelivery(endpoint caller, http:Request enrichedreq) {
        http:Response response;
        PhoneDeliver newDeliver;
        json reqPayload;

        log:printInfo(" Received order details from the phone store service");

        // Try parsing the JSON payload from the request
        match enrichedreq.getJsonPayload() {
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
        newDeliver.customerName = name.toString();
        newDeliver.address = address.toString();
        newDeliver.contactNumber = contact.toString();
        newDeliver.deliveryPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newDeliver.deliveryPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneDeliverDetails = check <json>newDeliver;
            // Create a JMS message

            jms:Message queueMessage2 = check DeliveryQueueJmsSessionSend.createTextMessage(phoneDeliverDetails.toString
                ());

            log:printInfo("Order delivery details added to the delivery queue'; CustomerName: '" + newDeliver.
                    customerName +
                    "', OrderedPhone: '" + newDeliver.deliveryPhoneName + "';");
            // Send the message to the JMS queue
            _ = jmsProducerDeliveryQueue->send(queueMessage2);
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
}
jms:Connection DeliveryQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a JMS session on top of the created connection
jms:Session DeliveryQueueJmsSessionReceive = new(DeliveryQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumerDeliveryQueue {
    session: DeliveryQueueJmsSessionReceive,
    queueName: "DeliveryQueue"
};
service<jms:Consumer> deliverySystem bind jmsConsumerDeliveryQueue {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message2) {
        log:printInfo("New order successfilly received from the Delivery Queue");
        // Retrieve the string payload using native function
        string stringPayload2 = check message2.getTextMessageContent();
        log:printInfo("Delivery details: " + stringPayload2);
        log:printInfo(" Delivery details sent to the customer successfully");
    }
}
