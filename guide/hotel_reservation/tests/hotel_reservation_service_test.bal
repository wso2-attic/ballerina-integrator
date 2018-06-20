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
    // Start the 'hotelReservationService' before running the test
    _ = test:startServices("hotel_reservation");
}

// Client endpoint
endpoint http:Client clientEP {
    url:"http://localhost:9092/hotel"
};

// Function to test Hotel reservation service
@test:Config
function testHotelReservationService() {
    // Initialize the empty http requests and responses
    http:Request req;

    // Test the 'reserveRoom' resource
    // Construct a request payload
    json payload = {
        "Name":"Alice",
        "ArrivalDate":"12-03-2018",
        "DepartureDate":"13-04-2018",
        "Preference":"Air Conditioned"
    };

    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/reserve", payload);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Hotel reservation service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload = check response.getJsonPayload();
    json expected = {"Status":"Success"};
    test:assertEquals(resPayload, expected, msg = "Response mismatch!");
}

@test:AfterSuite
function afterFunc() {
    // Stop the 'hotelReservationService' after running the test
    test:stopServices("hotel_reservation");
}
