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

// Common request Payload
json requestPayload = {
    "ArrivalDate":"12-03-2018",
    "DepartureDate":"13-04-2018",
    "VehicleType":"Car"
};

// Client endpoint
endpoint http:Client clientEP {
    url:"http://localhost:9093/car"
};

// Function to test resource 'driveSg'
@test:Config
function testResourceDriveSg () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/driveSg", req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Company\":\"DriveSG\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":5}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}

// Function to test resource 'dreamCar'
@test:Config
function testResourceDreamCar () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/dreamCar", req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Company\":\"DreamCar\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":6}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}

// Function to test resource 'sixt'
@test:Config
function testResourceSixt () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/sixt", req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Company\":\"Sixt\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":7}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}
