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
import ballerina/io;

// hospital service endpoint
http:Client hospitalEP = new("http://localhost:9090");

@http:ServiceConfig {
    basePath: "/healthcare"
}

service healthcareService on new http:Listener(9091) {
    // Resource to make an appointment reservation with bill payment
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/newdoctor"
    }

    resource function addDoctor(http:Caller caller, http:Request request, string category) {
        var requestPayload = request.getJsonPayload();
        if (requestPayload is json) {
            json newDoctorPayload = {
                "name": requestPayload.name,
                "hospital": requestPayload.hospital,
                "category": requestPayload.category,
                "availability": requestPayload.availability,
                "fee": requestPayload.fee
            };
            // call doctor creation
            http:Response addDoctorResponse = addNewDoctor(caller, untaint newDoctorPayload);
            respondToClient(caller, addDoctorResponse);
        } else {
            respondToClient(caller, createErrorResponse(400, "Not a valid Json payload"));
        }
    }
}

function addNewDoctor(http:Caller caller, json payload) returns http:Response {
    http:Request addDoctorRequest = new;
    addDoctorRequest.setPayload(payload);
    http:Response | error addDoctorResponse = new;

    addDoctorResponse = hospitalEP->post("/healthcare/admin/newdoctor", addDoctorRequest);

    return handleResponse(addDoctorResponse);
}

// util method to handle response
function handleResponse(http:Response | error response) returns http:Response {
    if (response is http:Response) {
        return response;
    } else {
        return createErrorResponse(500, <string> response.detail().message);
    }
}

// util method to create error response
function createErrorResponse(int statusCode, string msg) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = statusCode;
    errorResponse.setPayload(msg);
    return errorResponse;
}

//util method to respond to a caller and handle error
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}
