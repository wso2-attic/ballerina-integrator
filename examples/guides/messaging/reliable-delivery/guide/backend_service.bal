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

import ballerina/log;
import ballerina/http;


//export http listner port on 9095
listener http:Listener httpListener = new(9095);

// Healthcare Service, which allows users to channel doctors online
@http:ServiceConfig { basePath: "/testservice" }
service healthcareService on httpListener {
    // Resource that allows users to make appointments
    @http:ResourceConfig { 
        methods: ["POST"], 
        consumes: ["application/json"],
        produces: ["application/json"],
        path: "/test" }
    resource function make_appointment(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
                string[] headerNames = request.getHeaderNames();
                string headers = "";
                foreach var header in headerNames {
                    headers = headers + "[" + header + ": ";
                    string headerVal = request.getHeader(untaint header);
                    headers = headers + headerVal + "] , ";
                }
                log:printInfo("HIT!! - payload = " + payload.toString() + "Headers = " + headers);
                json responseMessage = { "Message": "This is Test Service" };
                response.setPayload(responseMessage);
                response.statusCode = 500;
            check caller->respond(response);
        } else {
            response.statusCode = 500;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            check caller->respond(response);
            return;
        }

    }
}