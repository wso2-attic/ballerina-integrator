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

package TravelAgency.HotelReservation;

import ballerina.test;
import ballerina.net.http;

// Common request Payload
json requestPayload = {
                          "ArrivalDate":"12-03-2018",
                          "DepartureDate":"13-04-2018",
                          "Location":"Changi"
                      };

// Create HTTP Client
http:HttpClient httpClient = create http:HttpClient("http://localhost:9092/hotel", {});

// Start the service before running the tests
function beforeTest () {
    _ = test:startService("hotelReservationService");
}

// Function to test resource 'miramar'
function testResourceMiramar () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Set request payload
    request.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/miramar", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot reserve room!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Hotel reservation service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"HotelName\":\"Miramar\",\"FromDate\":\"12-03-2018\"," +
                      "\"ToDate\":\"13-04-2018\",\"DistanceToLocation\":6}";
    test:assertStringEquals(response.getJsonPayload().toString(), expected, "Response mismatch!");
}

// Function to test resource 'aqueen'
function testResourceAqueen () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Set request payload
    request.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/aqueen", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot reserve room!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Hotel reservation service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"HotelName\":\"Aqueen\",\"FromDate\":\"12-03-2018\"," +
                      "\"ToDate\":\"13-04-2018\",\"DistanceToLocation\":4}";
    test:assertStringEquals(response.getJsonPayload().toString(), expected, "Response mismatch!");
}

// Function to test resource 'elizabeth'
function testResourceElizabeth () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Set request payload
    request.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/elizabeth", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot reserve room!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Hotel reservation service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"HotelName\":\"Elizabeth\",\"FromDate\":\"12-03-2018\"," +
                      "\"ToDate\":\"13-04-2018\",\"DistanceToLocation\":2}";
    test:assertStringEquals(response.getJsonPayload().toString(), expected, "Response mismatch!");
}
