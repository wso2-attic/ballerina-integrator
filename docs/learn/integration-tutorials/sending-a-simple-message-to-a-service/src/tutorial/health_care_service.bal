// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

// CODE-SEGMENT-BEGIN: segment_1
listener http:Listener httpListener = new(9092);
// CODE-SEGMENT-END: segment_1
// CODE-SEGMENT-BEGIN: segment_4
http:Client healthcareEndpoint = new("http://localhost:9095/healthcare");
// CODE-SEGMENT-END: segment_4

// Health Care Management is done using an in-memory map.
map<json> appoinmentMap = {

};

// RESTful service
// CODE-SEGMENT-BEGIN: segment_2
@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on httpListener
// CODE-SEGMENT-END: segment_2
{
    // CODE-SEGMENT-BEGIN: segment_3
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getdoctor/{category}"
    }
    resource function getDoctorInCategory(http:Caller caller, http:Request req, string category)
    // CODE-SEGMENT-END: segment_3
    {
        // CODE-SEGMENT-BEGIN: segment_5
        var response = healthcareEndpoint->get("/queryDoctor/" +<@untainted> category);
        // CODE-SEGMENT-END: segment_5
        // CODE-SEGMENT-BEGIN: segment_6
        if (response is http:Response && response.getJsonPayload() is json) {
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    // CODE-SEGMENT-END: segment_6
    }
}
