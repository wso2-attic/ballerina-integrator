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

# Gmail client endpoint declaration with oAuth2 client configurations
gmail:GmailConfiguration gmailConfig = {
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            config: {
                grantType: http:DIRECT_TOKEN,
                config: {
                    accessToken: "ya29.GlwgB6Nbn8FLTeNy4qJGDywJyheIKt0M7OUu5Q5yxrEA0033LMHM4BA-kzxbpmdjwkhaO6CJJ5_mdR55EjP-g-5Bk-wo2HdIiWCjiwDJfzNU-111X2yB_DJOagZMHQ",
                    refreshConfig: {
                        refreshUrl: gmail:REFRESH_URL,
                        refreshToken: "1/sUpgjclqE_KwPnqGlVs6pvFHjL2_fefkI_OOXuxZolJNOUjpmQdr-uYuQoameOic",
                        clientId: "924967501288-12je7sdbirp167m61gsrujbnni0c5u58.apps.googleusercontent.com",
                        clientSecret: "iDPT9j2_gMiUGgxDyEv8bj7i&grant_type=refresh_token&refresh_token=1%2FsUpgjclqE_KwPnqGlVs6pvFHjL2_fefkI_OOXuxZolJNOUjpmQdr-uYuQoameOic&client_id=924967501288-12je7sdbirp167m61gsrujbnni0c5u58.apps.googleusercontent.com"
                    }
                }
            }
        }
    }
};

//Gmail client that handles sending payloads to email address
gmail:Client gmailClient = new(gmailConfig);
//Listener endpoint that the service binds to 
listener http:Listener endpoint = new(9091);

//Change the service URL to base /surgery
@http:ServiceConfig {
    basePath: "/surgery"
}
service gmailConnector on new http:Listener(9091) {

    //Decorate "reserve" resource path to accept POST requests
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/reserve"
    }
    resource function settleReservation(http:Caller caller, http:Request request) {
        var payload = request.getJsonPayload();
        http:Response response = new;

        if (payload is json) {
            http:Client clientEp = new("http://localhost:9090");

            var backendResponse = clientEp->post("/grandoaks/categories/surgery/reserve", untaint payload);

            if (backendResponse is http:Response) {
                var jsonPayload = backendResponse.getJsonPayload();

                if (jsonPayload is json) {
                    response = sendToGmail(untaint jsonPayload);
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

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error in responding", err = result);
        }
    }
}

// Sends the payload to Gmail
function sendToGmail(json jsonPayload) returns http:Response {
    string messageBody = jsonPayload.toString();
    http:Response response = new;

    string userId = "me";
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = "aquib.zt@gmail.com";
    messageRequest.sender = "aquib@wso2.com";
    messageRequest.subject = "Gmail Connector test : Payment Status";
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_PLAIN;

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
        io:println("Error: ", sendMessageResponse);
        response.setPayload("Failed to send the Email");
    }

    return response;
}
