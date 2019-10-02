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
import ballerina/log;

// Service endpoint
listener http:Listener travelAgencyEP = new(9090);

// Client endpoint to communicate with Airline reservation service
http:Client airlineReservationEP = new("http://localhost:9091/airline");

// Client endpoint to communicate with Hotel reservation service
http:Client hotelReservationEP = new("http://localhost:9092/hotel");

http:Response outResponse = new;

http:Caller requestCaller = new;

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {

    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    resource function arrangeTour(http:Caller caller, http:Request inRequest) returns error? {
        requestCaller = <@untainted>caller;

        // Try parsing the JSON payload from the user request
        json|error payload = inRequest.getJsonPayload();
        check self.validateRequest(payload);
        check self.reserveAirline(payload);
        check self.reserveHotel(payload);

        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        var result = caller->respond(outResponse);
        handleError(result);
        return;
    }

    // CODE-SEGMENT-BEGIN: segment_1
    function validateRequest(json|error payload) returns error? {
        if (payload is json) {
            // Valid JSON payload for all JSON parameters
            if (payload.Name == () || payload.ArrivalDate == () || payload.DepartureDate == () ||
                payload.Preference.Airline == () || payload.Preference.Accommodation == ()) {
                outResponse.statusCode = 400;
                outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
                var result = requestCaller->respond(outResponse);
                handleError(result);
                if (result is error) {
                    return result;
                }
            }
        } else {
            // NOT a valid JSON payload
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            var result = requestCaller->respond(outResponse);
            handleError(result);
            if (result is error) {
                return result;
            }
        }
    }
    // CODE-SEGMENT-END: segment_1

    // CODE-SEGMENT-BEGIN: segment_2
    function reserveAirline(json|error payload) returns error? {
        // Reserve airline ticket for the user by calling Airline reservation service
        // construct the payload
        json jsonPayload = check payload;
        json outReqJsonPayloadAirline = {
            Name: check jsonPayload.Name,
            ArrivalDate: check jsonPayload.ArrivalDate,
            DepartureDate: check jsonPayload.DepartureDate,
            Preference: check jsonPayload.Preference.Airline
        };

        http:Request outReqPayloadAirline = new;
        outReqPayloadAirline.setJsonPayload(<@untainted>outReqJsonPayloadAirline);

        // Send a post request to airlineReservationService with appropriate payload and get response
        http:Response inResponseAirline = check airlineReservationEP->post("/reserve", outReqPayloadAirline);

        // Get the reservation status
        var airlineResponsePayload = check inResponseAirline.getJsonPayload();
        string airlineStatus = airlineResponsePayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (!equalIgnoreCase(airlineStatus, "Success")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
                    "Provide a valid 'Preference' for 'Airline' and try again"});
            var result = requestCaller->respond(outResponse);
            handleError(result);
            if (result is error) {
                return result;
            }
        }
    }
    // CODE-SEGMENT-END: segment_2

    // CODE-SEGMENT-BEGIN: segment_3
    function reserveHotel(json|error payload) returns error? {
        json jsonPayload = check payload;
        json outRequestJsonPayloadHotel = {
            Name: check jsonPayload.Name,
            ArrivalDate: check jsonPayload.ArrivalDate,
            DepartureDate: check jsonPayload.DepartureDate,
            Preference: check jsonPayload.Preference.Accommodation
        };

        http:Request outRequestPayloadHotel = new;
        outRequestPayloadHotel.setJsonPayload(<@untainted>outRequestJsonPayloadHotel);

        // Send a post request to hotelReservationService with appropriate payload and get response
        http:Response inResponseHotel = check hotelReservationEP->post("/reserve", outRequestPayloadHotel);

        // Get the reservation status
        var hotelResponsePayload = check inResponseHotel.getJsonPayload();
        string hotelStatus = hotelResponsePayload.Status.toString();
        // If reservation status is negative, send a failure response to user
        if (!equalIgnoreCase(hotelStatus, "Success")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
                    "Provide a valid 'Preference' for 'Accommodation' and try again"});
            var result = requestCaller->respond(outResponse);
            handleError(result);
            if (result is error) {
                return result;
            }
        }
    }
    // CODE-SEGMENT-END: segment_3

}

function handleError(error? result) {
    if (result is error) {
        log:printError(result.reason(), err = result);
    }
}
