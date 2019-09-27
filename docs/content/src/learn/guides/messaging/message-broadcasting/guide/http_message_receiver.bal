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
import ballerina/io;

// Init the HTTP client for appointment service
http:Client appointmentClient = new("http://localhost:9090");

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

// Initialize a topic publisher using the created session
jms:TopicPublisher topicPublisher = new(jmsSession, topicPattern = "appointmentTopic");

// Export http listner port on 9091
listener http:Listener httpListener = new(9091);

// Healthcare Service, which allows users to channel doctors online
@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcareService on httpListener {
    // Resource that allows users to make appointments
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function make_appointment(http:Caller caller, http:Request request) returns error? {
        http:Response clientResponse = new;
        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            json responseMessage;
            // Invoke HTTP service to make the appointment
            var response = appointmentClient->post("/grandoaks/categories/surgery/reserve ", untaint payload);
            if (response is http:Response) {
                var resPayload = response.getJsonPayload();
                if (resPayload is json) {
                    log:printInfo("Response is : " + resPayload.toString());
                    // Send the message to the Topic
                    var topicMessage = jmsSession.createTextMessage(resPayload.toString());
                    if (topicMessage is jms:Message) {
                        check topicPublisher->send(topicMessage);
                        // Construct a success message for the response
                        responseMessage = {                             "Message": "Your appointment is successfully placed"};
                        log:printInfo("New appointment added to the JMS topic; Patient: " + payload.patient.name.toString());
                    } else {
                        log:printError("Error occured while adding appointment to the JMS topic");
                        responseMessage = {                             "Message": "Internal error occured while storing the appointment"};
                        clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                    }
                } else {
                    log:printError("Error parsing response from appointment service " + <string> resPayload.detail().message);
                    clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                    responseMessage = {                         "Message": "Internal error occured while storing the appointment"};
                }
            } else {
                log:printError("Error when invoking appointment service " + <string> response.detail().message);
                clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                responseMessage = {                     "Message": "Internal error occured when invoking appointment service"};
            }
            // Send response to the user
            clientResponse.setJsonPayload(responseMessage);
            check caller->respond(clientResponse);
        } else {
            clientResponse.statusCode = 400;
            clientResponse.setJsonPayload({
                "Message": "Invalid payload - Not a valid JSON payload"
            });
            check caller->respond(clientResponse);
            return;
        }

    }
}

