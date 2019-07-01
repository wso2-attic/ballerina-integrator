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
    "From":"Colombo",
    "To":"Changi"
};

// Client endpoint
http:Client clientEP = new("http://localhost:9091/airline");

// Function to test resource 'flightConcord'
@test:Config
function testResourceFlightConcord () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/qatarAirways", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200,
            msg = "Airline reservation service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Airline\":\"Qatar Airways\", \"ArrivalDate\":\"12-03-2018\"," +
            " \"ReturnDate\":\"13-04-2018\", \"From\":\"Colombo\", \"To\":\"Changi\", \"Price\":278}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from concord is invalid");
        }
    } else {
        test:assertFail(msg = "Response from concord is invalid");
    }
}

// Function to test resource 'flightAsiana'
@test:Config
function testResourceFlightAsiana () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/asiana", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200,
            msg = "Airline reservation service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Airline\":\"Asiana\", \"ArrivalDate\":\"12-03-2018\", \"ReturnDate\":\"13-04-2018\", " +
            "\"From\":\"Colombo\", \"To\":\"Changi\", \"Price\":275}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from flightAsiana is invalid");
        }
    } else {
        test:assertFail(msg = "Response from flightAsiana is invalid");
    }
}

// Function to test resource 'flightEmirates'
@test:Config
function testResourceFlightEmirates () {
    // Initialize the empty http requests and responses
    http:Request req = new;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/emirates", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200,
        msg = "Airline reservation service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        string expected = "{\"Airline\":\"Emirates\", \"ArrivalDate\":\"12-03-2018\", \"ReturnDate\":\"13-04-2018\", " +
        "\"From\":\"Colombo\", \"To\":\"Changi\", \"Price\":273}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Response from flightEmirates is invalid");
        }
    } else {
        test:assertFail(msg = "Response from flightEmirates is invalid");
    }
}
