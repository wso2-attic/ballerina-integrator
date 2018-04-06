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

package HotelReservation;

import ballerina/http;

// Service endpoint
endpoint http:ServiceEndpoint hotelEP {
    port:9092
};

// Hotel reservation service
@http:ServiceConfig {basePath:"/hotel"}
service<http:Service> hotelReservationService bind hotelEP {
    
    // Resource 'miramar', which checks about hotel 'Miramar'
    @http:ResourceConfig {methods:["POST"], path:"/miramar", consumes:["application/json"],
                          produces:["application/json"]}
    miramar (endpoint client, http:Request request) {
        http:Response response = {};
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
        // Valid JSON payload
            json payload => reqPayload = payload;
        // NOT a valid JSON payload
            any | null => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                //return;
            }
        }
        
        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || location == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(response);
            //return;
        }

        // Mock logic
        // Details of the hotel
        json hotelDetails = {
                                "HotelName":"Miramar",
                                "FromDate":arrivalDate,
                                "ToDate":departureDate,
                                "DistanceToLocation":6
                            };
        // Response payload
        response.setJsonPayload(hotelDetails);
        // Send the response to the client
        _ = client -> respond(response);
    }

    // Resource 'aqueen', which checks about hotel 'Aqueen'
    @http:ResourceConfig {methods:["POST"], path:"/aqueen", consumes:["application/json"],
                          produces:["application/json"]}
    aqueen (endpoint client, http:Request request) {
        http:Response response = {};
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
        // Valid JSON payload
            json payload => reqPayload = payload;
        // NOT a valid JSON payload
            any | null => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                //return;
            }
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || location == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(response);
            //return;
        }

        // Mock logic
        // Details of the hotel
        json hotelDetails = {
                                "HotelName":"Aqueen",
                                "FromDate":arrivalDate,
                                "ToDate":departureDate,
                                "DistanceToLocation":4
                            };
        // Response payload
        response.setJsonPayload(hotelDetails);
        // Send the response to the client
        _ = client -> respond(response);
    }

    // Resource 'elizabeth', which checks about hotel 'Elizabeth'
    @http:ResourceConfig {methods:["POST"], path:"/elizabeth", consumes:["application/json"],
                          produces:["application/json"]}
    elizabeth (endpoint client, http:Request request) {
        http:Response response = {};
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
        // Valid JSON payload
            json payload => reqPayload = payload;
        // NOT a valid JSON payload
            any | null => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                //return;
            }
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || location == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(response);
            //return;
        }

        // Mock logic
        // Details of the hotel
        json hotelDetails = {
                                "HotelName":"Elizabeth",
                                "FromDate":arrivalDate,
                                "ToDate":departureDate,
                                "DistanceToLocation":2
                            };
        // Response payload
        response.setJsonPayload(hotelDetails);
        // Send the response to the client
        _ = client -> respond(response);
    }
}
