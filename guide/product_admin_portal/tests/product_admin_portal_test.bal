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

import ballerina/test;
import ballerina/http;

@test:BeforeSuite
function beforeFunc() {
    // Start the 'product_admin_portal' service before running the test
    _ = test:startServices("product_admin_portal");
}

// Client endpoint
endpoint http:Client clientEP {
    url:"http://localhost:9090/product"
};

// Function to test 'product_admin_portal' service
@test:Config
function testProductAdminPortal () {
    // Initialize empty http request
    http:Request req;

    // Test the 'updatePrice' resource
    // Construct a request payload
    json payload = {
        "Username":"Admin",
        "Password":"Admin",
        "Product":"ABC",
        "Price":100.00
    };

    req.setJsonPayload(payload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/updatePrice", request = req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200,
        msg = "product admin service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload = check response.getJsonPayload();
    json expected = {"Status":"Success"};
    test:assertEquals(resPayload, expected, msg = "Response mismatch!");
}

@test:AfterSuite
function afterFunc() {
    // Stop the 'product_admin_portal' service after running the test
    test:stopServices("product_admin_portal");
}
