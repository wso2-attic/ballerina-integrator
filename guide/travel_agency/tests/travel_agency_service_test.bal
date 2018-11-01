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

// Client endpoint
endpoint http:Client clientEP {
    url: "http://localhost:9090/travel"
};

// Mock airline service endpoint
endpoint http:Listener airlineEP {
    port: 9091
};

// Mock hotel service endpoint
endpoint http:Listener hotelEP {
    port: 9092
};

// Mock car service endpoint
endpoint http:Listener carEP {
    port: 9093
};

// Function to test Travel agency service
@test:Config
function testTravelAgencyService() {
    // Initialize the empty http requests and responses
    http:Request req;

    // Test the 'arrangeTour' resource
    // Construct a request payload
    json payload = {
        "Name":"Alice",
        "ArrivalDate":"12-03-2018",
        "DepartureDate":"13-04-2018",
        "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}
    };

    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/arrangeTour", payload);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Travel agency service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    json resPayload = check response.getJsonPayload();
    json expected = {"Message":"Congratulations! Your journey is ready!!"};
    test:assertEquals(resPayload, expected, msg = "Response mismatch!");
}

// Travel agency service depends on three external services.
// Therefore, to test it we need those three services to be upped.
// Hence, we need to manually start those services or create mock services.

// Airline reservation mock service
@http:ServiceConfig { basePath: "/airline" }
service<http:Service> airlineReservationService bind airlineEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/reserve" }
    reserveTicket(endpoint client, http:Request request) {
        _ = client -> respond({"Status":"Success"});
    }
}

// Hotel reservation mock service
@http:ServiceConfig { basePath: "/hotel" }
service<http:Service> hotelReservationService bind hotelEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/reserve" }
    reserveRoom(endpoint client, http:Request request) {
        _ = client -> respond({"Status":"Success"});
    }
}

// Car rental mock service
@http:ServiceConfig { basePath: "/car" }
service<http:Service> carRentalService bind carEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/rent" }
    rentCar(endpoint client, http:Request request) {
        _ = client -> respond({"Status":"Success"});
    }
}
