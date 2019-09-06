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

import ballerina/test;
import ballerina/http;
import ballerina/io;

http:Client clientEP = new("http://localhost:9090/hello");

// Define the data provider for function testHelloServiceResponse.
@test:Config {
    dataProvider: "helloServiceDataProvider"
}

// This function verifies for the response of the service.
// It asserts for the response text and the status code.
// Following function covers two test cases.
// TC001 - Verify the response when a valid name is sent.
// TC002 - Verify the response when a valid space string is sent as " ".
function testHelloServiceResponse(string name, string result) {
    http:Request request = new;
    string payload = name;
    request.setPayload(payload);

    var response = clientEP->post("/sayHello ", request);

    if (response is http:Response) {
        test:assertEquals(response.getTextPayload(), result, msg = "assertion failed, name mismatch");
        test:assertEquals(response.statusCode, 200, msg = "Status Code mismatch!");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

// This function passes data to testHelloServiceResponse function for two test cases.
function helloServiceDataProvider() returns string[][] {
    return [
                ["John","Hello John"], 
                [" ","Hello  "]
           ];
}

// Data provider for negative test case.
@test:Config {
    dataProvider: "helloServiceDataProviderNegative"
}

// This negative function verifies the failure when an empty string is sent.
// This function covers the below test case.
// NTC001 - Verify the response when an invalid empty string is sent.
function testHelloServiceResponseNegative(string name) {
    http:Request request = new;
    string payload = name;
    request.setPayload(payload);

    var response = clientEP->post("/sayHello ", request);

    if (response is http:Response) {
        test:assertEquals(response.getTextPayload(), "Payload is empty ", msg = "assertion failed_negative");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

// This function passes data to testHelloServiceResponseNegative function for two test cases.
function helloServiceDataProviderNegative() returns string[][] {
    return [
                [""]
           ];
}
