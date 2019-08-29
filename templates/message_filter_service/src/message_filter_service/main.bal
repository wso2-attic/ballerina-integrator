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
import ballerina/config;

// Listener for filter service
listener http:Listener filterServiceEP = new(config:getAsInt("LISTENER_PORT"));

// Endpoint for the backend service
http:Client stdInfoEP = new(config:getAsString("CLIENT_ENDPOINT"));

// REST service to select students who qualified from an exam
@http:ServiceConfig {
    basePath: "/filterService"
}
service filterService on filterServiceEP {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/filterMarks"
    }
    resource function filterMarks(http:Caller caller, http:Request request) {

        boolean isQualified = false;

        // Request to be sent to the backend service
        http:Request requestToBackend = new;

        // Get the JSON payload from the request
        var reqPayload = request.getJsonPayload();

        if (reqPayload is json) {
            string stdName = <string>reqPayload.name;
            json[] subjects = <json[]>reqPayload.subjects;

            foreach var subject in subjects {
                int mark = <int>subject.marks;
                if (mark >= 60) {
                    isQualified = true;
                } else {
                    isQualified = false;
                }
            }
            requestToBackend.setJsonPayload(<@untainted> reqPayload);
        } else {
            http:Response errResp = new;
            errResp.statusCode = http:STATUS_BAD_REQUEST;
            errResp.setJsonPayload({"Error":"Invalid request payload"});
            var err = caller->respond(errResp);
            handleResponseError(err);
            return;
        }

        // Send response from the service
        map<json> responseJson = {"status":""};
        int statusCode;
        if (isQualified) {
            // Call the backend service to persist student record if student has qualified
            var response = stdInfoEP->post("/v2/5b2cc4292f00007900ebd395", requestToBackend);
            if (response is http:Response) {
                statusCode = response.statusCode;
                responseJson["status"] = "Qualified";
            } else {
                log:printError("Invalid response", err = response);
            }
        } else {
            responseJson["status"] = "Not Qualified";
        }

        http:Response responseFromService = new;
        responseFromService.statusCode = http:STATUS_OK;
        responseFromService.setJsonPayload(<@untainted> responseJson);
        var err = caller->respond(responseFromService);
        handleResponseError(err);
    }
}

function handleResponseError(error? err) {
    if (err is error) {
        log:printError("Responding failed", err = err);
    }
}
