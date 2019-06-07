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

// Endpoint URL of the backend service
http:Client locationEP = new("http://localhost:9090");

// Service to reserve appointments
@http:ServiceConfig {
    basePath: "/healthcare"
}
service contentBasedRouting on new http:Listener(9080) {

    // Reserve appointments on the type of "category"
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function CBRResource(http:Caller outboundEP, http:Request req, string category) {

        // Request message payload
        var jsonMsg = req.getJsonPayload();
        if (jsonMsg is json) {
            string hospitalDesc = jsonMsg["hospital"].toString();
            string doctorName = jsonMsg["doctor"].toString();
            string hospitalName = "";

            http:Response|error clientResponse;
            if (hospitalDesc != "") {
                match hospitalDesc {
                    "grand oak community hospital" => hospitalName = "grandoaks";
                    "clemency medical center" => hospitalName = "clemency";
                    "pine valley community hospital" => hospitalName = "pinevalley";
                    _ => respondWithError(outboundEP, "Hospital name is invalid.", "Hospital name is invalid.");
                }
                string sendPath = "/" + hospitalName + "/categories/" + category + "/reserve";

                // Call the backend service related to the hospital
                clientResponse = locationEP -> post(untaint sendPath, untaint jsonMsg);
            } else {
                respondWithError(outboundEP, "JSON Path $hospital cannot be empty.", "Hospital cannot be empty.");
                return;
            }
            if (clientResponse is http:Response) {
                var result = outboundEP->respond(clientResponse);
                handleErrorResponse(result, "Error at the backend");
            } else {
                respondWithError(outboundEP, <string>clientResponse.detail().message, "Backend service does not properly respond");
            }
        } else {
            respondWithError(outboundEP, untaint <string>jsonMsg.detail().message, "Request is not JSON");
        }
    }
}

# Error handle the responses
function handleErrorResponse(http:Response|error? response, string errorMessage) {
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
