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

import ballerina/config;
import ballerina/http;
import ballerina/log;

// Endpoint for the backend service.
http:Client healthcareEndpoint = new("https://reqres.in");
// Constants for request paths.
const BACKEND_EP_PATH = "/api/users";

@http:ServiceConfig {
    basePath: "/laboratory"
}
service scienceLabService on new http:Listener(config:getAsInt("LISTENER_PORT")) {
    // Schedule an appointment.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/user"
    }
    resource function addUser(http:Caller caller, http:Request request) {
        // Extract payload from the request.
        xml|error requestPayload = request.getXmlPayload();

        if (requestPayload is xml) {
            // Transform the payload into the json which is required by the backend service.
            json|error modifiedPayload = {
                "name": requestPayload.name.getTextValue(),
                "job": requestPayload.job.getTextValue()
            };

            if (modifiedPayload is json) {
                // Create new request to call the back-end service with the modified payload.
                http:Request backendRequest = new();
                backendRequest.setPayload(<@untainted> modifiedPayload);
                // Define new response
                http:Response|error backendResponse = new();
                backendResponse = healthcareEndpoint->post(BACKEND_EP_PATH, backendRequest);

                if (backendResponse is http:Response) {
                    // Get json payload from the backend response.
                    json|error resJson = backendResponse.getJsonPayload();

                    if (resJson is json) {
                        // Convert the json payload to xml.
                        string id = resJson.id.toString();
                        string name = resJson.name.toString();
                        string job = resJson.job.toString();
                        string created = resJson.createdAt.toString();

                        xml|error resXml = xml `<response>
                            <status>successful</status>
                            <id>${id}</id>
                            <name>${name}</name>
                            <job>${job}</job>
                            <createdAt>${created}</createdAt>
                        </response>`;

                        if (resXml is xml) {
                            respondAndHandleError(caller, http:STATUS_OK, <@untainted> resXml);
                        } else {
                            logAndRespondError(caller, "Converting backend json response to xml failed.", resXml,
                                http:STATUS_INTERNAL_SERVER_ERROR);
                        }

                    } else {
                        logAndRespondError(caller, "Invalid response from backend service.", resJson,
                            http:STATUS_INTERNAL_SERVER_ERROR);
                    }

                } else {
                    logAndRespondError(caller, "Error in sending request to backend service.", backendResponse, 
                        http:STATUS_INTERNAL_SERVER_ERROR);
                }

            } else {
                logAndRespondError(caller, "Transforming xml to json failed.", modifiedPayload, 
                    http:STATUS_INTERNAL_SERVER_ERROR);
            }

        } else {
            logAndRespondError(caller, "Invalid request payload.", requestPayload, http:STATUS_BAD_REQUEST);
        }
    }
}

// Log and respond error.
function logAndRespondError(http:Caller caller, string errMsg, error err, int statusCode) {
    log:printError(errMsg, err = err);
    respondAndHandleError(caller, statusCode, errMsg);
}

// Send the response back to the client and handle responding errors.
function respondAndHandleError(http:Caller caller, int resCode, json|xml|string payload) {
    http:Response res = new;
    res.statusCode = resCode;
    res.setPayload(payload);
    var respond = caller->respond(res);
    if (respond is error) {
        log:printError("Error occurred while responding", err = respond);
    }
}
