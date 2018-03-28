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

package TravelAgency;

import ballerina.net.http;
import ballerina.test;

// Start the service before running the tests
function beforeTest () {
    _ = test:startService("travelAgencyService");
}

// Function to test the Travel agency service
// NOTE: Run the other 3 services (Airline, Hotel and Car) before running this test
function testTravelAgencyService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9090/travel", {});
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Request Payload
    json requestPayload = {
                              "ArrivalDate":"12-03-2018",
                              "DepartureDate":"13-04-2018",
                              "From":"Colombo",
                              "To":"Changi",
                              "VehicleType":"Car",
                              "Location":"Changi"
                          };

    // Set request payload
    request.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/arrangeTour", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot arrange tour!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Travel agency service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    // Flight details
    string expectedFlight = "{\"Airline\":\"Emirates\",\"ArrivalDate\":\"12-03-2018\",\"ReturnDate\":\"13-04-2018\"," +
                            "\"From\":\"Colombo\",\"To\":\"Changi\",\"Price\":273}";
    test:assertStringEquals(response.getJsonPayload().Flight.toString(), expectedFlight, "Response mismatch!");
    // Hotel details
    string expectedHotel = "{\"HotelName\":\"Elizabeth\",\"FromDate\":\"12-03-2018\"," +
                           "\"ToDate\":\"13-04-2018\",\"DistanceToLocation\":2}";
    test:assertStringEquals(response.getJsonPayload().Hotel.toString(), expectedHotel, "Response mismatch!");
}
