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
import ballerina/config;
import ballerina/http;
import ballerina/log;
import wso2/gmail;

// CODE-SEGMENT-BEGIN: segment_1
// Gmail client endpoint declaration with oAuth2 client configurations.
gmail:GmailConfiguration gmailConfig = {
    clientConfig:{
        accessToken: config:getAsString("ACCESS_TOKEN"),
         refreshConfig: {
            refreshUrl: gmail:REFRESH_URL,
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET")
        }
    }
}; 

// CODE-SEGMENT-END: segment_1

const RECIPIENT_EMAIL = "someone@gmail.com";
const SENDER_EMAIL = "somebody@gmail.com";

// Gmail client that handles sending payloads to email address.
// CODE-SEGMENT-BEGIN: segment_2
gmail:Client gmailClient = new(gmailConfig);
// CODE-SEGMENT-END: segment_2

// Hospital service endpoint.
http:Client hospitalEP = new("http://localhost:9095");

const string GRAND_OAK = "grand oak community hospital";
const string CLEMENCY = "clemency medical center";
const string PINE_VALLEY = "pine valley community hospital";

// Change the service URL to base `/surgery`.
@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on new http:Listener(9092) {
    // Resource to make an appointment reservation with bill payment.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function scheduleAppointment(http:Caller caller, http:Request request, string category) {
        var requestPayload = request.getJsonPayload();
        if (requestPayload is json) {
            // Tranform the request payload to the format expected by the backend end service.
            json reservationPayload = {
                "patient": {
                    "name": <json>requestPayload.name,
                    "dob": <json>requestPayload.dob,
                    "ssn": <json>requestPayload.ssn,
                    "address": <json>requestPayload.address,
                    "phone": <json>requestPayload.phone,
                    "email": <json>requestPayload.email
                },
                "doctor": <json>requestPayload.doctor,
                "hospital": <json>requestPayload.hospital,
                "appointment_date": <json>requestPayload.appointment_date
            };
            // Call appointment creation.
            http:Response reservationResponse = createAppointment(caller, <@untainted> reservationPayload, category);

            json | error responsePayload = reservationResponse.getJsonPayload();
            if (responsePayload is json) {
                // Check if the json payload is actually an appointment confirmation response.
                if (responsePayload.appointmentNumber is ()) {
                    respondToClient(caller, createErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, 
                    <@untainted> responsePayload.toString()));
                    return;
                }
                // Call payment settlement.
                http:Response paymentResponse = doPayment(<@untainted> responsePayload);
                // Send the response back to the client.
                //respondToClient(caller, paymentResponse);

                json | error paymentResPayload = paymentResponse.getJsonPayload();
                if (paymentResPayload is json) {
                    respondToClient(caller, sendEmail(generateEmail(<@untainted> paymentResPayload)));
                } else {
                    respondToClient(caller, createErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, "Backend did not respond with json"));
                }
            } else {
                respondToClient(caller, createErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, "Backend did not respond with json"));
            }
        } else {
            respondToClient(caller, createErrorResponse(http:STATUS_BAD_REQUEST, "Not a valid Json payload"));
        }
    }
}

// Generates an email based on the recieved payload.
// CODE-SEGMENT-BEGIN: segment_3
function generateEmail(json jsonPayload) returns string {
    string email = "<html>";
    email += "<h1> GRAND OAK COMMUNITY HOSPITAL </h1>";
    email += "<h3> Patient Name : " + jsonPayload.patient.name.toString() + "</h3>";
    email += "<p> This is a confimation for your appointment with Dr." + jsonPayload.doctor.name.toString() + "</p>";
    email += "<p> Assigned time : " + jsonPayload.doctor.availability.toString() + "</p>";
    email += "<p> Appointment number : " + jsonPayload.appointmentNumber.toString() + "</p>";
    email += "<p> Appointment date : " + jsonPayload.appointmentDate.toString() + "</p>";
    email += "<p><b> FEE : " + jsonPayload.fee.toString() + "</b></p>";

    return email;
}
// CODE-SEGMENT-END: segment_3

// Sends the payload to an Email account.
// CODE-SEGMENT-BEGIN: segment_4
function sendEmail(string email) returns http:Response {
    string messageBody = email;
    http:Response response = new;

    string userId = "me";
    gmail:MessageRequest messageRequest = {

    };
    messageRequest.recipient = RECIPIENT_EMAIL;
    messageRequest.sender = SENDER_EMAIL;
    messageRequest.subject = "Gmail Connector test : Payment Status";
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    // Send the message.
    var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest);

    if (sendMessageResponse is [string, string]) {
        // If successful, print the message ID and thread ID.
        [string, string] [messageId, threadId] = sendMessageResponse;
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
// CODE-SEGMENT-END: segment_4

// Function to call hospital service backend and make an appointment reservation.
function createAppointment(http:Caller caller, json payload, string category) returns http:Response {
    string hospitalName = payload.hospital.toString();
    http:Request reservationRequest = new;
    reservationRequest.setPayload(payload);
    http:Response | error reservationResponse = new;
    match hospitalName {
        GRAND_OAK => {
            reservationResponse = hospitalEP->
            post("/grandoaks/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        CLEMENCY => {
            reservationResponse = hospitalEP->
            post("/clemency/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        PINE_VALLEY => {
            reservationResponse = hospitalEP->
            post("/pinevalley/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        _ => {
            respondToClient(caller, createErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, 
                                                                            "Unknown hospital name"));
        }
    }
    return handleResponse(reservationResponse);
}

// Function to call hospital service backend and make payment for an appointment reservation.
function doPayment(json payload) returns http:Response {
    http:Request paymentRequest = new;
    paymentRequest.setPayload(payload);
    http:Response | error paymentResponse = hospitalEP->post("/healthcare/payments", paymentRequest);
    return handleResponse(paymentResponse);
}

// Util method to handle response.
function handleResponse(http:Response | error response) returns http:Response {
    if (response is http:Response) {
        return response;
    } else {
        return createErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, <string> response.detail().toString());
    }
}

// Util method to respond to a caller and handle error.
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}

// Util method to create error response.
function createErrorResponse(int statusCode, string msg) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = statusCode;
    errorResponse.setPayload(msg);
    return errorResponse;
}
