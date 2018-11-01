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
endpoint http:Client clientEP {
    url: "http://localhost:9090/travel"
};

// Mock airline service endpoint
endpoint http:Listener airlineReservationEP {
    port: 9091
};

// Mock hotel service endpoint
endpoint http:Listener hotelReservationEP {
    port: 9092
};

// Mock car service endpoint
endpoint http:Listener carEP {
    port: 9093
};

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
    http:Response response = check clientEP->post("/arrangeTour", requestPayload);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "Travel agency service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    // Flight details
    string expectedFlight = "{\"Airline\":\"Emirates\", \"ArrivalDate\":\"12-03-2018\", \"ReturnDate\":\"13-04-2018\","
        + " \"From\":\"Colombo\", \"To\":\"Changi\", \"Price\":273}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.Flight.toString(), expectedFlight, msg = "Response mismatch!");
    // Hotel details
    string expectedHotel = "{\"HotelName\":\"Elizabeth\", \"FromDate\":\"12-03-2018\"," +
        " \"ToDate\":\"13-04-2018\", \"DistanceToLocation\":2}";
    test:assertEquals(resPayload.Hotel.toString(), expectedHotel, msg = "Response mismatch!");
}

// Travel agency service depends on three external services.
// Therefore, to test it we need those three services to be upped.
// Hence, we need to manually start those services or create mock services.

// Airline reservation mock service
@http:ServiceConfig { basePath: "/airline" }
service<http:Service> airlineReservationService bind airlineReservationEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/qatarAirways" }
    flightConcord (endpoint client, http:Request request) {
        http:Response response;
        _ = client -> respond({"Airline":"Qatar Airways", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":278});
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/asiana" }
    flightAsiana (endpoint client, http:Request request) {
        http:Response response;
        _ = client -> respond({"Airline":"Asiana", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":275});
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/emirates" }
    flightEmirates (endpoint client, http:Request request) {
        http:Response response;
        _ = client -> respond({"Airline":"Emirates", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018",
                "From":"Colombo", "To":"Changi", "Price":273});
    }
}

// Hotel reservation mock service
@http:ServiceConfig { basePath: "/hotel" }
service<http:Service> hotelReservationService bind hotelReservationEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/miramar" }
    miramar(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"HotelName":"Miramar", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":6});
        _ = client -> respond(response);
    }

   // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/aqueen" }
    aqueen(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"HotelName":"Aqueen", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":4});
        _ = client -> respond(response);
    }

   // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/elizabeth" }
    elizabeth(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"HotelName":"Elizabeth", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
                "DistanceToLocation":2});
        _ = client -> respond(response);
    }
}

// Car rental mock service
@http:ServiceConfig { basePath: "/car" }
service<http:Service> carRentalService bind carEP {
    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/driveSg" }
    driveSg(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"Company":"DriveSG", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":5});
        _ = client -> respond(response);
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/dreamCar" }
    dreamCar(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"Company":"DreamCar", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":6});
        _ = client -> respond(response);
    }

    // Mock resource
    @http:ResourceConfig { methods: ["POST"], path: "/sixt" }
    sixt(endpoint client, http:Request request) {
        http:Response response;
        response.setJsonPayload({"Company":"Sixt", "VehicleType":"Car", "FromDate":"12-03-2018",
                "ToDate":"13-04-2018", "PricePerDay":7});
        _ = client -> respond(response);
    }
}
