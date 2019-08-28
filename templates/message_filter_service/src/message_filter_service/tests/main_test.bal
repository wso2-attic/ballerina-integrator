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

import ballerina/test;
import ballerina/http;

// Client endpoint
http:Client clientEP = new("http://localhost:9090/filterService");

string expectedStatusResponse = "Not Qualified";

@test:Config {}
function testMessageFilter() {

    // Initialize the empty http request
    http:Request request = new;
    // Construct the request payload
    json payload = {"name":"Anne","subjects":[{"subject":"Maths","marks": 80},{"subject":"Science","marks":40}]};
    // Set JSON payload to request
    request.setJsonPayload(<@untainted> payload);
    // Send 'POST' request and obtain the response
    var response = clientEP->post("/filterMarks", request);

    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Message filter service did not respond with 200 OK signal!");
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            string status = <string>resPayload.status;
            test:assertEquals(status, expectedStatusResponse, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from Message filter service is invalid");
        }
    } else {
        test:assertFail(msg = "Response from Message filter service is invalid");
    }
}
