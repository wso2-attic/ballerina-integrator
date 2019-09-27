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

import ballerina/http;
import ballerina/test;

// Client endpoint
http:Client clientEP = new("http://localhost:9090/travel");

// Mock airline service endpoint
listener http:Listener airlineReservationEP = new(9091);

// Mock hotel service endpoint
listener http:Listener hotelReservationEP = new(9092);

// Mock car service endpoint
listener http:Listener carEP = new(9093);

// Function to test the Travel agency service
@test:Config
function testTravelAgencyService() {
    // Request Payload
    json requestPayload = {
        "ArrivalDate": "12-03-2018",
        "DepartureDate": "13-04-2018",
        "From": "Colombo",
        "To": "Changi",
        "VehicleType": "Car",
        "Location": "Changi"
    };

    // Send a 'post' request and obtain the response
    var response = clientEP->post("/arrangeTour", requestPayload);
    if(response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "Travel agency service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        // Flight details
        string expectedFlight = "{\"Airline\":\"Emirates\", \"ArrivalDate\":\"12-03-2018\", \"ReturnDate\":\"13-04-2018\","
        + " \"From\":\"Colombo\", \"To\":\"Changi\", \"Price\":273}";
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.Flight.toString(), expectedFlight, msg = "Response mismatch!");
            // Hotel details
            string expectedHotel = "{\"HotelName\":\"Elizabeth\", \"FromDate\":\"12-03-2018\"," +
            " \"ToDate\":\"13-04-2018\", \"DistanceToLocation\":2}";
            test:assertEquals(resPayload.Hotel.toString(), expectedHotel, msg = "Response mismatch!");
        }   else {
            test:assertFail(msg = "Payload from the post request to arrangeTour is invalid");
        }
    } else {
        test:assertFail(msg = "Response from the post request to arrangeTour is invalid");
    }
}

// Travel agency service depends on three external services.
// Therefore, to test it we need those three services to be upped.
// Hence, we need to manually start those services or create mock services.

// Airline reservation mock service
@http:ServiceConfig { basePath: "/airline" }
service airlineReservationService on airlineReservationEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/qatarAirways" }
    resource function flightConcord (http:Caller caller, http:Request request) returns error? {
        _ = check caller->respond({"Airline":"Qatar Airways", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":278});
        return;
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/asiana" }
    resource function flightAsiana (http:Caller caller, http:Request request) returns error? {
        _ = check caller->respond({"Airline":"Asiana", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":275});
        return;
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/emirates" }
    resource function flightEmirates (http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        _ = check caller->respond({"Airline":"Emirates", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":273});
        return;
    }
}

// Hotel reservation mock service
@http:ServiceConfig { basePath: "/hotel" }
service hotelReservationService on hotelReservationEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/miramar" }
    resource function miramar(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"HotelName":"Miramar", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":6});
        _ = check caller->respond(response);
        return;
    }

   // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/aqueen" }
    resource function aqueen(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"HotelName":"Aqueen", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":4});
        _ = check caller->respond(response);
        return;
    }

   // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/elizabeth" }
    resource function elizabeth(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"HotelName":"Elizabeth", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":2});
        _ = check caller->respond(response);
        return;
    }
}

// Car rental mock service
@http:ServiceConfig { basePath: "/car" }
service carRentalService on carEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/driveSg" }
    resource function driveSg(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"Company":"DriveSG", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":5});
        _ = check caller->respond(response);
        return;
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/dreamCar" }
    resource function dreamCar(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"Company":"DreamCar", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":6});
        _ = check caller->respond(response);
        return;
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/sixt" }
    resource function sixt(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        response.setJsonPayload({"Company":"Sixt", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":7});
        _ = check caller->respond(response);
        return;
    }
}
