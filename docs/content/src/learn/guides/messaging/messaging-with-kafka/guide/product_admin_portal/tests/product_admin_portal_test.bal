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

type Payload record {|
    string Username;
    string Password;
    string Product;
    float Price;
|};

// Client endpoint
http:Client httpClient = new http:Client("http://localhost:9090/product");

// Function to test 'product_admin_portal' service
@test:Config
function testProductAdminPortal () {
    // Initialize empty http request
    http:Request req = new();

    // Test the 'updatePrice' resource
    // Construct a request payload
    Payload payload = { Username:"Admin", Password:"Admin", Product:"ABC", Price:100.00 };
    json|error payloadJson = json.convert(payload);

    if (payloadJson is error) {
        test:assertFail(msg = "Payload JSON returned error.");
    } else {

        req.setJsonPayload(payloadJson);
        // Send a 'post' request and obtain the response
        http:Response|error postResponse = httpClient->post("/updatePrice", req);

        if (postResponse is error) {
            test:assertFail(msg = "HTTP post method returned error.");
        } else {
            // Expected response code is 200
            test:assertEquals(postResponse.statusCode, 200,
                    msg = "product admin service did not respond with 200 OK signal!"
            );
            // Check whether the response is as expected
            var resPayload = postResponse.getJsonPayload();
            if (resPayload is error) {
                test:assertFail(msg = "Response payload returned error.");
            } else {
                json expected = {"Status":"Success"};
                test:assertEquals(resPayload, expected, msg = "Response mismatch!");
            }
        }
    }
}
