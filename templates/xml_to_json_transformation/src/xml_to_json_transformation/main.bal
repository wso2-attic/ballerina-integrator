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
import ballerina/jsonutils;
import ballerina/xmlutils;

// This is the endpoint of the backend service that is being called.
http:Client healthcareEndpoint = new("https://reqres.in");
// "/api/users" is a constant for the request path of the backend service.
const BACKEND_EP_PATH = "/api/users";

// This is the base path of the service you are creating.
@http:ServiceConfig {
    basePath: "/laboratory"
}
service scienceLabService on new http:Listener(config:getAsInt("LISTENER_PORT")) {
    // Schedule an appointment. "/user" is the resource path of your service.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/user"
    }
    resource function addUser(http:Caller caller, http:Request request) returns error? {
        json user = {};
        // Extract user from the request and convert it from XML to JSON. 
        // If malformed, respond back with HTTP 400 error.
        xml|error req = request.getXmlPayload();
        if (req is xml) {
            user = check jsonutils:fromXML(req);
        } else {
            http:Response res = new();
            res.statusCode = http:STATUS_BAD_REQUEST;
            var result = caller->respond(res);
            if (result is error) {
                log:printError("Error occurred while responding", err = result);
            }
        }
        // Create request and send to the backend
        http:Request backendReq = new();
        backendReq.setPayload(user);
        http:Response backendRes = check healthcareEndpoint->post(BACKEND_EP_PATH, backendReq);
        // Get the JSON payload, convert it back to XML, and respond back to the client
        var result = caller->respond(check xmlutils:fromJSON(check backendRes.getJsonPayload()));
        if (result is error) {
            log:printError("Error occurred while responding", err = result);
        }
    }
}

function handleResult(error? result) {
    if (result is error) {
        log:printError("Error occurred while responding", err = result);
    }
}
