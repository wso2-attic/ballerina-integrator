// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// Service endpoint
listener http:Listener travelAgencyEP = new(9090);

// Client endpoint to communicate with Airline reservation service
http:Client airlineReservationEP = new("http://localhost:9091/airline");

// Client endpoint to communicate with Hotel reservation service
http:Client hotelReservationEP = new("http://localhost:9092/hotel");

// Client endpoint to communicate with Car rental service
http:Client carRentalEP = new("http://localhost:9093/car");

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {

    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    resource function arrangeTour(http:Caller caller, http:Request inRequest) returns error? {
        http:Response outResponse = new;
        json inReqPayload = {};

        // Try parsing the JSON payload from the user request
        var payload = inRequest.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload
            inReqPayload = payload;
        } else {
            // NOT a valid JSON payload
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // Json payload format for an http out request
        json outReqPayload = {
            Name: check inReqPayload.Name,
            ArrivalDate: check inReqPayload.ArrivalDate,
            DepartureDate: check inReqPayload.DepartureDate,
            Preference:""
        };

        json airlinePreference = check inReqPayload.Preference.Airline;
        json hotelPreference = check inReqPayload.Preference.Accommodation;
        json carPreference = check inReqPayload.Preference.Car;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (outReqPayload.Name == () || outReqPayload.ArrivalDate == () || outReqPayload.DepartureDate == () ||
            airlinePreference == () || hotelPreference == () || carPreference == ()) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // Reserve airline ticket for the user by calling Airline reservation service
        // construct the payload
        json outReqJsonPayloadAirline = {
            Name: check outReqPayload.Name,
            ArrivalDate: check outReqPayload.ArrivalDate,
            DepartureDate: check outReqPayload.DepartureDate,
            Preference: airlinePreference
        };

        http:Request outReqPayloadAirline = new;
        outReqPayloadAirline.setJsonPayload(<@untainted>outReqJsonPayloadAirline);

        // Send a post request to airlineReservationService with appropriate payload and get response
        http:Response inResAirline = check airlineReservationEP->post("/reserve", outReqPayloadAirline);

        // Get the reservation status
        var airlineResPayload = check inResAirline.getJsonPayload();
        string airlineStatus = airlineResPayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (equalIgnoreCase(airlineStatus, "Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
                    "Provide a valid 'Preference' for 'Airline' and try again"});
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // Reserve hotel room for the user by calling Hotel reservation service
        // construct the payload
        json outReqJsonPayloadHotel = {
            Name: check outReqPayload.Name,
            ArrivalDate: check outReqPayload.ArrivalDate,
            DepartureDate: check outReqPayload.DepartureDate,
            Preference: hotelPreference
        };

        http:Request outReqPayloadHotel = new;
        outReqPayloadHotel.setJsonPayload(<@untainted>outReqJsonPayloadHotel);

        // Send a post request to hotelReservationService with appropriate payload and get response
        http:Response inResHotel = check hotelReservationEP->post("/reserve", outReqPayloadHotel);

        // Get the reservation status
        var hotelResPayload = check inResHotel.getJsonPayload();
        string hotelStatus = hotelResPayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (equalIgnoreCase(hotelStatus, "Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
                    "Provide a valid 'Preference' for 'Accommodation' and try again"});
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // Renting car for the user by calling Car rental service
        // construct the payload
        json outReqJsonPayloadCar = {
            Name: check outReqPayload.Name,
            ArrivalDate: check outReqPayload.ArrivalDate,
            DepartureDate: check outReqPayload.DepartureDate,
            Preference: carPreference
        };

        http:Request outReqPayloadCar = new;
        outReqPayloadCar.setJsonPayload(<@untainted>outReqJsonPayloadCar);

        // Send a post request to carRentalService with appropriate payload and get response
        http:Response inResCar = check carRentalEP->post("/rent", outReqPayloadCar);

        // Get the rental status
        var carResPayload = check inResCar.getJsonPayload();
        string carRentalStatus = carResPayload.Status.toString();
        // If rental status is negative, send a failure response to user
        if (equalIgnoreCase(carRentalStatus, "Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to rent car! " +
                    "Provide a valid 'Preference' for 'Car' and try again"});
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        var result = caller->respond(outResponse);
        handleError(result);
        return ();
    }

}
