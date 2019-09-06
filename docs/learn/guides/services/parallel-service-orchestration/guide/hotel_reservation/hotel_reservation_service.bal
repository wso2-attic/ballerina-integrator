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
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"hotel_reservation_service",
//    tag:"v1.0"
//}
//
//@docker:Expose{}

//@kubernetes:Ingress {
//  hostname:"ballerina.guides.io",
//  name:"ballerina-guides-hotel-reservation-service",
//  path:"/"
//}
//
//@kubernetes:Service {
//  serviceType:"NodePort",
//  name:"ballerina-guides-hotel-reservation-service"
//}
//
//@kubernetes:Deployment {
//  image:"ballerina.guides.io/hotel_reservation_service:v1.0",
//  name:"ballerina-guides-hotel-reservation-service"
//}

// Service endpoint
listener http:Listener hotelEP = new (9092);

// Hotel reservation service
@http:ServiceConfig {basePath:"/hotel"}
service hotelReservationService on hotelEP {

    // Resource 'miramar', which checks about hotel 'Miramar'
    @http:ResourceConfig {methods:["POST"], path:"/miramar", consumes:["application/json"],
        produces:["application/json"]}
    resource function miramar (http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is error) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            _ = check caller->respond(response);
            return;
        } else {
            reqPayload = payload;
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || location == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
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
        response.setJsonPayload(untaint hotelDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'aqueen', which checks about hotel 'Aqueen'
    @http:ResourceConfig {methods:["POST"], path:"/aqueen", consumes:["application/json"],
        produces:["application/json"]}
    resource function aqueen (http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is error) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            _ = check caller->respond(response);
            return;
        } else {
            reqPayload = payload;
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || location == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
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
        response.setJsonPayload(untaint hotelDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'elizabeth', which checks about hotel 'Elizabeth'
    @http:ResourceConfig {methods:["POST"], path:"/elizabeth", consumes:["application/json"],
        produces:["application/json"]}
    resource function elizabeth (http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is error) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            _ = check caller->respond(response);
            return;
        } else {
            reqPayload = payload;
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json location = reqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || location == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
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
        response.setJsonPayload(untaint hotelDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }
}
