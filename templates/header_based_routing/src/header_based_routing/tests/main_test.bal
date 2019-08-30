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

http:Client calculatorEP = new("http://localhost:9090/calculatorService");

@test:Config{}
function testAddOperation () {
    map<json> inputJson = {"valueOne": 45, "valueTwo": 78};
    http:Request request = new;
    request.setJsonPayload(inputJson, "application/json");
    request.setHeader("operation", "add");

    int expectedResponse = 123;

    var response = calculatorEP->post("/calculate", request);
    if(response is http:Response){
        test:assertEquals(response.statusCode, 200, msg = "Content based routing service did not respond with 200
                OK signal!");
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            int result = <int>resPayload.result;
            test:assertEquals(result, expectedResponse, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from Content based routing service is invalid");
        }
    } else {
        test:assertFail(msg = "Response from Message filter service is invalid");
    }
}

@test:Config{}
function testSubtractOperation () {
    map<json> inputJson = {"valueOne": 45, "valueTwo": 78};
    http:Request request = new;
    request.setJsonPayload(inputJson, "application/json");
    request.setHeader("operation", "subtract");

    int expectedResponse = -33;

    var response = calculatorEP->post("/calculate", request);
    if(response is http:Response){
        test:assertEquals(response.statusCode, 200, msg = "Content based routing service did not respond with 200
                OK signal!");
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            int result = <int>resPayload.result;
            test:assertEquals(result, expectedResponse, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from Content based routing service is invalid");
        }
    } else {
        test:assertFail(msg = "Response from Message filter service is invalid");
    }
}
