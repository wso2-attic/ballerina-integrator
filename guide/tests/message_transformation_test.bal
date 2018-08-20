
// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/mysql;
import ballerina/test;

boolean serviceStarted;

function startService() {
    serviceStarted = test:startServices("message_transformation");
}

@test:Config {
    before: "startService",
    after: "stopService"
}

function testMessageTransformation() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");
    json payload = { "id": 105, "name": "saneth", "city": "Colombo 03", "gender": "male" };
    json response1 = { "id": 105, "city": "Colombo 03", "gender": "male", "fname": "saneth",
        "results": { "Com_Maths": "A", "Physics": "B", "Chemistry": "C" } };

    http:Request req = new;
    req.setJsonPayload(payload);
    // Send a GET request to the specified endpoint
    var response = httpEndpoint->post("/contentfilter", req);
    match response {
        http:Response resp => {
            var jsonRes = check resp.getJsonPayload();
            test:assertEquals(jsonRes, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function stopService() {
    test:stopServices("message_transformation");
}
