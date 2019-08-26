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
import ballerina/test;

json expectedResponse = ${expectedJsonResponse};

http:Client clientEP = new("http://localhost:9090");

boolean serviceStarted = false;
function startService() {
    serviceStarted = test:startServices("scatter_gather_service");
}

function stopService() {
    test:stopServices("scatter_gather_service");
}

@test:Config {
    before: "startService",
    after: "stopService"
}
function testScatterGather() {
    test:assertTrue(serviceStarted, msg = "Unable to start the service");
    var response = clientEP->get("/endpoints/call");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Scatter-Gather service did not respond with 200 OK signal!");
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload, expectedResponse, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from Scatter-Gather service is invalid");
        }
    } else {
        test:assertFail(msg = "Response from Scatter-Gather service is invalid");
    }
}