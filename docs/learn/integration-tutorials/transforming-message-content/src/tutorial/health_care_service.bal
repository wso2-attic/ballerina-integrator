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

import ballerina/http;
import ballerina/log;

// Endpoint for the backend service
http:Client healthcareEndpoint = new("http://localhost:9095");

// Constants for request paths
const GRAND_OAK_EP_PATH = "/grandoaks/categories/";
const CLEMENCY_EP_PATH = "/clemency/categories/";
const PINE_VALLEY_EP_PATH = "/pinevalley/categories/";

// Constant for error code
const string ERROR_CODE = "Sample Error";

@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on new http:Listener(9092) {

    // Get list of doctors in a given category
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getdoctor/{category}"
    }
    resource function getDoctorInCategory(http:Caller caller, http:Request req, string category)
    {
        var response = healthcareEndpoint->get("/queryDoctor/" + <@untainted> category);
        if (response is http:Response && response.getJsonPayload() is json) {
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    }

    // Reserve appointments on the type of "category"
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function scheduleAppointment(http:Caller caller, http:Request request, string category) {

        // Define new response
        http:Response | error backendResponse = new();

        // CODE-SEGMENT-BEGIN: segment_1
        // Extract payload from the request
        var requestPayload = request.getJsonPayload();

        if (requestPayload is json) {
            // Get hospital name
            string hospitalName = requestPayload.hospital.toString();

            // Transform the payload into the format which is required by the backend service
            json modifiedPayload = {
                "patient": {
                    "name": <json>requestPayload.name,
                    "dob": <json>requestPayload.dob,
                    "ssn": <json>requestPayload.ssn,
                    "address": <json>requestPayload.address,
                    "phone": <json>requestPayload.phone,
                    "email": <json>requestPayload.email,
                    "cardNo": <json>requestPayload.cardNo
                },
                "doctor": <json>requestPayload.doctor,
                "hospital": hospitalName,
                "appointmentDate": <json>requestPayload.appointment_date
            };
            // CODE-SEGMENT-END: segment_1

            // Create new request to call the back-end service with the modified payload
            http:Request backendRequest = new();
            backendRequest.setPayload(<@untainted> modifiedPayload);

            match hospitalName {
                "grand oak community hospital" => {
                    backendResponse = healthcareEndpoint->post(GRAND_OAK_EP_PATH + <@untainted> category 
                                                                                + "/reserve",backendRequest);
                }
                "clemency medical center" => {
                    backendResponse = healthcareEndpoint->post(CLEMENCY_EP_PATH + <@untainted> category 
                                                                                + "/reserve",backendRequest);
                }
                "pine valley community hospital" => {
                    backendResponse = healthcareEndpoint->post(PINE_VALLEY_EP_PATH + <@untainted> category 
                                                                                + "/reserve",backendRequest);
                }
                 _=> {
                     error err = error(ERROR_CODE, message = "Unknown hospital name.");
                     backendResponse = err;
                 }
            }
    }
            else{
                error err = error(ERROR_CODE, message = "Invalid json request payload.");
                 backendResponse = err;
            }
        
        if (backendResponse is http:Response) {
            // Send response to the client
            respondAndHandleError(caller, <@untainted> backendResponse, "Error in responding to client!");
        } else {
            // Send error response to the client
            createAndSendErrorResponse(caller, <@untainted> backendResponse, "Error in sending request to backend service.");
        }
    }
}

// Function to create the error response
function createAndSendErrorResponse(http:Caller caller, error sourceError, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code
    response.statusCode = 500;
    //Set the error message to the error response payload
    response.setPayload(<string> sourceError.detail().toString());
    respondAndHandleError(caller, response, respondErrorMsg);
}

// Function to send the response back to the client and handle the error
function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    // Send response to the caller
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}
