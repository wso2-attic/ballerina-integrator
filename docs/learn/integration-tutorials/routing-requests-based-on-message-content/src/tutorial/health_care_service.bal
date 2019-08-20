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

import ballerina/http;
import ballerina/log;

listener http:Listener httpListener = new(9092);

// Endpoint URL of the backend service
http:Client healthcareEndpoint = new("http://localhost:9095");

// RESTful service
@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on httpListener {

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

    // Reserve appointments in a hospital
    // CODE-SEGMENT-BEGIN: segment_1
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    // CODE-SEGMENT-END: segment_1
    // CODE-SEGMENT-BEGIN: segment_2
    resource function scheduleAppointment(http:Caller caller, http:Request req, string category)
    {
        // Get data from request message payload
        var jsonMsg = req.getJsonPayload();
        if (jsonMsg is json) {
            string hospitalDesc = jsonMsg.hospital.toString();
            string doctorName = jsonMsg.doctor.toString();
            string hospitalName = "";

            http:Response | error clientResponse;
            if (hospitalDesc != "") {
                match hospitalDesc {
                    "grand oak community hospital" =>hospitalName = "grandoaks";
                    "clemency medical center" =>hospitalName = "clemency";
                    "pine valley community hospital" =>hospitalName = "pinevalley";
                    _ => respondWithError(caller, "Hospital name is invalid.", "Hospital name is invalid.");
                }
                string sendPath = "/" + hospitalName + "/categories/" + category + "/reserve";

                // Call the backend service related to the hospital
                clientResponse = healthcareEndpoint->post(<@untainted> sendPath, <@untainted> jsonMsg);
            } else {
                respondWithError(caller, "JSON Path $hospital cannot be empty.", "Hospital cannot be empty.");
                return;
            }
            if (clientResponse is http:Response) {
                var result = caller->respond(clientResponse);
                handleErrorResponse(result, "Error at the backend");
            } else {
                respondWithError(caller, < string > clientResponse.detail().toString(),
                "Backend service does not properly respond");
            }
        } else {
            respondWithError(caller, <@untainted> < string > jsonMsg.detail().toString(), "Request is not JSON");
        }
    }
// CODE-SEGMENT-END: segment_2
}

# Error handle the responses
function handleErrorResponse(http:Response | error? response, string errorMessage) {
    if (response is error) {
        log:printError(errorMessage, err = response);
    }
}

# Respond in error cases
function respondWithError(http:Caller outboundEP, string payload, string failedMessage) {
    http:Response res = new;
    res.statusCode = 500;
    res.setPayload(payload);
    var result = outboundEP->respond(res);
    handleErrorResponse(result, failedMessage);
}
