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

@http:ServiceConfig {
    basePath: "/"
}
service serviceB on new http:Listener(9091) {
    // Service B only accepts requests made using the HTTP methods specified below.
    @http:ResourceConfig {
        methods: ["POST", "GET"],
        path: "/service-b"
    }
    resource function getResource(http:Caller caller, http:Request req) {
        log:printInfo("You have been successfully connected to Service B.");
        // Make the response for the request.
        http:Response res = new;
        res.setPayload("Welcome to Service B!");
        // Sends the response to the caller.
        var result = caller->respond(res);
        handleError(result);
    }
}
