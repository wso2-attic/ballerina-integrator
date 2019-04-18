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
import ballerina/test;

@test:Config {}
function testMessageTransformation() {
    // Invoking the main function
    http:Client httpEndpoint = new("http://localhost:9090");
    json payload = { "id": 105, "name": "saneth", "city": "Colombo 03", "gender": "male" };
    json expectedResponse = { "id": 105, "city": "Colombo 03", "gender": "male", "fname": "saneth",
        "results": { "Com_Maths": "A", "Physics": "B", "Chemistry": "C" } };

    http:Request req = new;
    req.setJsonPayload(payload);
    // Send a GET request to the specified endpoint
    var response = httpEndpoint->post("/contentfilter/filter", req);
    if (response is http:Response) {
        var jsonRes = response.getJsonPayload();
        test:assertEquals(jsonRes, expectedResponse);
    } else {
        test:assertFail(msg = "Failed to call the endpoint");
    }
}
