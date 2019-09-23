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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/io;

http:Client clientEP = new("http://localhost:9090/stockQuote");

@test:Config
// Function to test POST resource 'placeZOrder'.
function testResourcePlaceOrder() {
    // Initialize the empty http request.
    http:Request request = new;
    // Construct the request payload.
    xml payload = xml `<Order>
                           <Price>10.0</Price>
                           <Quantity>3</Quantity>
                           <Symbol>WSO2</Symbol>
                       </Order>`;

    request.setXmlPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/order", request);
    if (response is http:Response) {
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201,
            msg = "placeOrder resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getXmlPayload();
        if (resPayload is xml) {
            xmlns "http://services.samples" as ns;
            xmlns "http://services.samples/xsd" as ax21;
            test:assertEquals(resPayload[ns:response][ax21:status].getTextValue(), "Order has been created",
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

@test:Config
// Function to test GET resource 'getQuote'.
function testResourceGetQuote() {
    // Send 'GET' request and obtain the response.
    var response = clientEP->get("/quote/WSO2");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "getQuote resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getXmlPayload();
        if (resPayload is xml) {
            test:assertTrue(io:sprintf("%s", resPayload).contains("WSO2"), msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}
