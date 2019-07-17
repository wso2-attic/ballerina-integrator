// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/http;
import ballerina/log;
import wso2/gmail;

// Gmail client endpoint declaration with oAuth2 client configurations.
gmail:GmailConfiguration gmailConfig = {
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            config: {
                grantType: http:DIRECT_TOKEN,
                config: {
                    accessToken: "accessToken",
                    refreshConfig: {
                        refreshUrl: gmail:REFRESH_URL,
                        refreshToken: "refreshToken",
                        clientId: "clientId",
                        clientSecret: "clientSecret"
                    }
                }
            }
        }
    }
};

const RECIPIENT_EMAIL = "someone@gmail.com";
const SENDER_EMAIL = "somebody@gmail.com";


// Gmail client that handles sending payloads to email address.
gmail:Client gmailClient = new(gmailConfig);
// Listener endpoint that the service binds to.
listener http:Listener endpoint = new(9091);

//Change the service URL to base /surgery
@http:ServiceConfig {
    basePath: "/surgery"
}
service gmailConnector on new http:Listener(9091) {

    // Decorate "reserve" resource path to accept POST requests.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/reserve"
    }
    resource function settleReservation(http:Caller caller, http:Request request) {
        json|error payload = request.getJsonPayload();
        http:Response response = new;

        if (payload is json) {
            http:Client clientEp = new("http://localhost:9095");

            http:Response|error backendResponse = clientEp->post("/grandoaks/categories/surgery/reserve", 
                                                                                            untaint payload);

            if (backendResponse is http:Response) {
                json|error jsonPayload = backendResponse.getJsonPayload();
                
                if (jsonPayload is json) {
                    io:println("Appointment Confirmation Payload : " + jsonPayload.toString());
                    // Get the complete email and send it to the email address 
                    response = sendEmail(generateEmail(untaint jsonPayload));
                } else {
                    log:printError("Invalid Json payload recieved from backend");
                }
            } else {
                log:printError("Error in sending request to backend. Invalid response", err = backendResponse);
            }
        } else {
            response.statusCode = 500;
            response.setPayload("Payload is not a valid JSON format");
        }

        http:Response|error? result = caller->respond(response);
        if (result is error) {
            log:printError("Error in responding", err = result);
        }
    }
}

// Generates an email based on the recieved payload.
function generateEmail(json jsonPayload) returns string{
    string email = "<html>";
    email += "<h1> GRAND OAK COMMUNITY HOSPITAL </h1>";
    email += "<h3> Patient Name : " + jsonPayload.patient.name.toString() +"</h3>";
    email += "<p> This is a confimation for your appointment with Dr." + jsonPayload.doctor.name.toString() + "</p>";
    email += "<p> Assigned time : " + jsonPayload.doctor.availability.toString() + "</p>";
    email += "<p> Appointment number : " + jsonPayload.appointmentNumber.toString() + "</p>";
    email += "<p> Appointment date : " + jsonPayload.appointmentDate.toString() + "</p>";
    email += "<p><b> FEE : " + jsonPayload.fee.toString() + "</b></p>";

    return email;
}

// Sends the payload to an Email account.
function sendEmail(string email) returns http:Response {
    string messageBody = email;
    http:Response response = new;

    string userId = "me";
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = RECIPIENT_EMAIL;
    messageRequest.sender = SENDER_EMAIL;
    messageRequest.subject = "Gmail Connector test : Payment Status";
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    // Send the message.
    var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest);

    if (sendMessageResponse is (string, string)) {
        // If successful, print the message ID and thread ID.
        (string, string) (messageId, threadId) = sendMessageResponse;
        io:println("Sent Message ID: " + messageId);
        io:println("Sent Thread ID: " + threadId);

        json payload = {
            Message: "The email has been successfully sent",
            Recipient: messageRequest.recipient
        };
        response.setJsonPayload(payload, contentType = "application/json");
    } else {
        // If unsuccessful, print the error returned.
        log:printError("Failed to send the email", err = sendMessageResponse);
        response.setPayload("Failed to send the Email");
    }

    return response;
}