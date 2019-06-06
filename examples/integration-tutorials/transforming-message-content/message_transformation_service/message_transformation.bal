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

// Define endpoint for the backen service.
http:Client hospitalEP = new("http://localhost:9090");

// Constants for request paths.
const GRAND_OSK_EP_PATH = "/grandoaks/categories/";
const CLEMENCY_EP_PATH = "/clemency/categories/";
const PINE_VALLEY_EP_PATH = "/pinevalley/categories/";

// Constant for error code.
const string ERROR_CODE = "Sample Error";

@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcareService on new http:Listener(9091) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    // Function to transform the payload and call the reservation backend service.
    resource function makeReservation(http:Caller caller, http:Request request, string category) {
        // Extract payload from the request.
        var requestPayload = request.getJsonPayload();
        json modifiedPayload = {};
        string requestPath = "";

        // Define new response. 
        http:Response|error backendResponse = new();

        if (requestPayload is json) {
            // Get hospital name.
            string hospitalName = requestPayload.hospital.toString();
            // Transform the payload into the format which is required by the backend service.
            modifiedPayload = {
                "patient": {
                    "name": requestPayload.name,
                    "dob": requestPayload.dob,
                    "ssn": requestPayload.ssn,
                    "address": requestPayload.address,
                    "phone": requestPayload.phone,
                    "email": requestPayload.email,
                    "cardNo": requestPayload.cardNo
                },
                "doctor": requestPayload.doctor,
                "hospital": hospitalName,
                "appointment_date": requestPayload.appointment_date
            };
            // Log the modified payload.
            log:printInfo(modifiedPayload.toString());

            // Create new request to call the back-end service with the modified payload.
            http:Request backendRequest = new();
            backendRequest.setPayload(untaint modifiedPayload);

            match hospitalName {
                "grand oak community hospital" => {
                    backendResponse = hospitalEP->post(untaint string `${GRAND_OSK_EP_PATH}/${category}/reserve`,
                                                backendRequest);  
                }
                "clemency medical center" => {
                    backendResponse = hospitalEP->post(untaint string `${CLEMENCY_EP_PATH}/${category}/reserve`, 
                                                backendRequest); 
                }
                "pine valley community hospital" => {
                    backendResponse = hospitalEP->post(untaint string `${PINE_VALLEY_EP_PATH}/${category}/reserve`, 
                                                backendRequest);
                }          
                _ => {
                    error err = error(ERROR_CODE, { message: "Unknown hospital name."});
                    backendResponse = err;
                } 
            } 
        } else {
            error err = error(ERROR_CODE, { message: "Invalid json request payload."});
            backendResponse = err;
        }
        
        if (backendResponse is http:Response) {
            // Send response to the client.
            respondAndHandleError(caller, untaint backendResponse, "Error in responding to client!");
        } else {
            // Send error response to the client.
            createAndSendErrorResponse(caller, untaint backendResponse, "Error in sending request to backend service.");
        }
    }
}

// Function to create the error response.
function createAndSendErrorResponse(http:Caller caller, error sourceError, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code.
    response.statusCode = 500;
    //Set the error message to the error response payload.
    response.setPayload(<string> sourceError.detail().message);
    respondAndHandleError(caller, response, respondErrorMsg);
}

// Function to send the response back to the client and handle the error.
function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    // Send response to the caller.
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}
