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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;


// Function to test 'placeOrder' resource
@test:Config

function testResourceOrderDelivey() {

    endpoint http:Client httpEndpoint3 { url: "http://localhost:9090/placeOrder" };
    // Initialize the empty http request
    http:Request req;
    // Construct a request payload
    json payload = { "customerID": "C002", "productID": "P002", "quantity": "40000", "orderType": "wholesale" };
    req.setJsonPayload(payload);
    // Send a 'post' request and obtain the response
    http:Response response = check httpEndpoint3->post("/place", req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload = check response.getJsonPayload();
    json expected = { "Message": "Your order is successfully placed" };
    test:assertEquals(resPayload, expected, msg = "Response mismatch!");

}
