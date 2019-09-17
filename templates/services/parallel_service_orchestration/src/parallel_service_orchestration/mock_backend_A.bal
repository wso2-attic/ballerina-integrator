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

// By default Ballerina assumes that the service is to be exposed via HTTP/1.1.
@http:ServiceConfig {
    basePath: "/service-a"
}
service serviceA on new http:Listener(9091) {

    // Resource to handle GET requests for Resource A.
    @http:ResourceConfig {
        path: "/resource-a",
        methods: ["GET"]
    }
    resource function resourceA(http:Caller caller, http:Request request) {
        http:Response response = new;
        string reponseText = "Success response from Service A - Resource A";
        response.setTextPayload(reponseText);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response from Service A - Resource A", result);
        }
    }

    // Resource to handle GET requests for Resource B.
    @http:ResourceConfig {
        path: "/resource-b",
        methods: ["GET"]
    }
    resource function secondEndpoint(http:Caller caller, http:Request request) {
        http:Response response = new;
        string reponseText = "Success response from Service A - Resource B";
        response.setTextPayload(reponseText);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response from Service A - Resource B", result);
        }
    }
}
