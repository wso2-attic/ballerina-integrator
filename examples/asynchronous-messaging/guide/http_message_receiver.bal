// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/http;
import ballerina/jms;


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
jms:QueueSender jmsProducer = new(jmsSession, queueName = "appointments");

//export http listner port on 9091
listener http:Listener httpListener = new(9091);

// Healthcare Service, which allows users to channel doctors online
@http:ServiceConfig { basePath: "/healthcare" }
service healthcareService on httpListener {
    // Resource that allows users to make appointments
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    resource function make_appointment(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            json responseMessage;
            var queueMessage = jmsSession.createTextMessage(payload.toString());
            // Send the message to the JMS queue
            if (queueMessage is jms:Message) {
                check jmsProducer->send(queueMessage);
                // Construct a success message for the response
                responseMessage = { "Message": "Your appointment is successfully placed" };
                log:printInfo("New channel request added to the JMS queue; Patient: " + payload.patient.name.toString());
            } else {
                responseMessage = { "Message": "Error occured while placing the appointment" };
                log:printError("Error occured while adding channeling information to the JMS queue");
            }
            // Send response to the user
            response.setJsonPayload(responseMessage);
            check caller->respond(response);
        } else {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            check caller->respond(response);
            return;
        }

    }
}