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

// Service endpoint
endpoint http:ServiceEndpoint travelAgencyEP {
    port:9090
};

// Client endpoint to communicate with Airline reservation service
endpoint http:ClientEndpoint airlineReservationEP {
    targets:[{uri:"http://localhost:9091/airline"}]
};

// Client endpoint to communicate with Hotel reservation service
endpoint http:ClientEndpoint hotelReservationEP {
    targets:[{uri:"http://localhost:9092/hotel"}]
};

// Client endpoint to communicate with Car rental service
endpoint http:ClientEndpoint carRentalEP {
    targets:[{uri:"http://localhost:9093/car"}]
};

// Travel agency service to arrange a complete tour for a user
@http:serviceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {

    // Resource to arrange a tour
    @http:resourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    arrangeTour (endpoint client, http:Request inRequest) {
        http:Response outResponse = {};
        json airlinePreference;
        json hotelPreference;
        json carPreference;

        // Json payload format for an http out request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"", "Preference":""};

        // Try parsing the JSON payload from the user request
        var inReqPayload, inReqEntityErr = inRequest.getJsonPayload();
        if(inReqPayload != null) {
            outReqPayload.Name = inReqPayload.Name;
            outReqPayload.ArrivalDate = inReqPayload.ArrivalDate;
            outReqPayload.DepartureDate = inReqPayload.DepartureDate;
            airlinePreference = inReqPayload.Preference.Airline;
            hotelPreference = inReqPayload.Preference.Accommodation;
            carPreference = inReqPayload.Preference.Car;
        }

        // If payload parsing fails, send a "Bad Request" message as the response
        if (inReqEntityErr != null || outReqPayload.Name == null || outReqPayload.ArrivalDate == null ||
            outReqPayload.DepartureDate == null ||airlinePreference == null || hotelPreference == null ||
            carPreference == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            return;
        }


        // Reserve airline ticket for the user by calling Airline reservation service
        http:Request outReqAirline = {};
        http:Response inResAirline = {};
        // construct the payload
        json outReqPayloadAirline = outReqPayload;
        outReqPayloadAirline.Preference = airlinePreference;
        outReqAirline.setJsonPayload(outReqPayloadAirline);

        // Send a post request to airlineReservationService with appropriate payload and get response
        inResAirline, _ = airlineReservationEP -> post("/reserve", outReqAirline);

        // Get the reservation status
        var airlineResPayload, _ = inResAirline.getJsonPayload();
        string airlineReservationStatus = airlineResPayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (airlineReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
                                                  "Provide a valid 'Preference' for 'Airline' and try again"});
            _ = client -> respond(outResponse);
            return;
        }


        // Reserve hotel room for the user by calling Hotel reservation service
        http:Request outReqHotel = {};
        http:Response inResHotel = {};
        // construct the payload
        json outReqPayloadHotel = outReqPayload;
        outReqPayloadHotel.Preference = hotelPreference;
        outReqHotel.setJsonPayload(outReqPayloadHotel);

        // Send a post request to hotelReservationService with appropriate payload and get response
        inResHotel, _ = hotelReservationEP -> post("/reserve", outReqHotel);

        // Get the reservation status
        var hotelResPayload, _ = inResHotel.getJsonPayload();
        string hotelReservationStatus = hotelResPayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (hotelReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
                                                  "Provide a valid 'Preference' for 'Accommodation' and try again"});
            _ = client -> respond(outResponse);
            return;
        }


        // Renting car for the user by calling Car rental service
        http:Request outReqCar = {};
        http:Response inResCar = {};
        // construct the payload
        json outReqPayloadCar = outReqPayload;
        outReqPayloadCar.Preference = carPreference;
        outReqCar.setJsonPayload(outReqPayloadCar);

        // Send a post request to carRentalService with appropriate payload and get response
        inResCar, _ = carRentalEP -> post("/rent", outReqCar);

        // Get the rental status
        var carResPayload, _ = inResCar.getJsonPayload();
        string carRentalStatus = carResPayload.Status.toString();
        // If rental status is negative, send a failure response to user
        if (carRentalStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to rent car! " +
                                                  "Provide a valid 'Preference' for 'Car' and try again"});
            _ = client -> respond(outResponse);
            return;
        }


        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        _ = client -> respond(outResponse);
    }
}
