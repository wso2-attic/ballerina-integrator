//
//// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
////
//// WSO2 Inc. licenses this file to you under the Apache License,
//// Version 2.0 (the "License"); you may not use this file except
//// in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing,
//// software distributed under the License is distributed on an
//// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//// KIND, either express or implied. See the License for the
//// specific language governing permissions and limitations
//// under the License.
//
package TravelAgency.CarRental;
//
//import ballerina.test;
//import ballerina.net.http;
//
//// Function to test Car rental service
//function testCarRentalService () {
//    endpoint<http:HttpClient> httpEndpoint {
//        create http:HttpClient("http://localhost:9093/car", {});
//    }
//    // Initialize the empty http requests and responses
//    http:OutRequest request = {};
//    http:InResponse response = {};
//    http:HttpConnectorError err;
//
//    // Start the Car rental service
//    _ = test:startService("carRentalService");
//
//    // Test the 'rentCar' resource
//    // Construct a request payload
//    json payload = {
//                       "Name":"Alice",
//                       "ArrivalDate":"12-03-2018",
//                       "DepartureDate":"13-04-2018",
//                       "Preference":"Air Conditioned"
//                   };
//
//    request.setJsonPayload(payload);
//    // Send a 'post' request and obtain the response
//    response, err = httpEndpoint.post("/rent", request);
//    // 'err' is expected to be null
//    test:assertTrue(err == null, "Error: Cannot rent car!");
//    // Expected response code is 200
//    test:assertIntEquals(response.statusCode, 200, "Car rental service did not respond with 200 OK signal!");
//    // Check whether the response is as expected
//    test:assertStringEquals(response.getJsonPayload().toString(), "{\"Status\":\"Success\"}", "Response mismatch!");
//}
