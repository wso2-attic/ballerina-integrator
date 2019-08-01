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
http:Client clientEP  = new("http://localhost:9093/car");

// Function to test resource 'driveSg'
@test:Config
function testResourceDriveSg () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/driveSg", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Company\":\"DriveSG\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":5}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from driveSg is invalid");
        }
    } else {
        test:assertFail(msg = "Response from driveSg is invalid");
    }
}

// Function to test resource 'dreamCar'
@test:Config
function testResourceDreamCar () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/dreamCar", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Company\":\"DreamCar\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":6}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from dreamCar is invalid");
        }
    } else {
        test:assertFail(msg = "Response from dreamCar is invalid");
    }
}

// Function to test resource 'sixt'
@test:Config
function testResourceSixt () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/sixt", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "Car rental service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Company\":\"Sixt\", \"VehicleType\":\"Car\", \"FromDate\":\"12-03-2018\", " +
        "\"ToDate\":\"13-04-2018\", \"PricePerDay\":7}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from sixt is invalid");
        }
    } else {
        test:assertFail(msg = "Response from sixt is invalid");
    }
}
