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
//    name:"airline_reservation_service",
//    tag:"v1.0"
//}
//
//@docker:Expose{}

//@kubernetes:Ingress {
//  hostname:"ballerina.guides.io",
//  name:"ballerina-guides-airline-reservation-service",
//  path:"/"
//}
//
//@kubernetes:Service {
//  serviceType:"NodePort",
//  name:"ballerina-guides-airline-reservation-service"
//}
//
//@kubernetes:Deployment {
//  image:"ballerina.guides.io/airline_reservation_service:v1.0",
//  name:"ballerina-guides-airline-reservation-service"
//}

// Service endpoint
listener http:Listener airlineEP = new(9091);

// Airline reservation service
@http:ServiceConfig {basePath:"/airline"}
service airlineReservationService on airlineEP {

    // Resource 'flightConcord', which checks about airline 'Qatar Airways'
    @http:ResourceConfig {methods:["POST"], path:"/qatarAirways", consumes:["application/json"],
        produces:["application/json"]}
    resource function flightConcord (http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is error) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            _ = check caller->respond(response);
        } else {
            reqPayload = payload;
        }

        json arrivalDate = reqPayload.ArrivalDate;
        json departureDate = reqPayload.DepartureDate;
        json fromPlace = reqPayload.From;
        json toPlace = reqPayload.To;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || fromPlace == () || toPlace == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
        }

        // Mock logic
        // Details of the airline
        json flightDetails = {
            "Airline":"Qatar Airways",
            "ArrivalDate":arrivalDate,
            "ReturnDate":departureDate,
            "From":fromPlace,
            "To":toPlace,
            "Price":278
        };
        // Response payload
        response.setJsonPayload(untaint flightDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'flightAsiana', which checks about airline 'Asiana'
    @http:ResourceConfig {methods:["POST"], path:"/asiana", consumes:["application/json"],
        produces:["application/json"]}
    resource function flightAsiana (http:Caller caller, http:Request request) returns error? {
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
        json fromPlace = reqPayload.From;
        json toPlace = reqPayload.To;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || arrivalDate == () || fromPlace == () || toPlace == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
        }

        // Mock logic
        // Details of the airline
        json flightDetails = {
            "Airline":"Asiana",
            "ArrivalDate":arrivalDate,
            "ReturnDate":departureDate,
            "From":fromPlace,
            "To":toPlace,
            "Price":275
        };
        // Response payload
        response.setJsonPayload(untaint flightDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'flightEmirates', which checks about airline 'Emirates'
    @http:ResourceConfig {methods:["POST"], path:"/emirates", consumes:["application/json"],
        produces:["application/json"]}
    resource function flightEmirates (http:Caller caller, http:Request request) returns error? {
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
        json fromPlace = reqPayload.From;
        json toPlace = reqPayload.To;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || fromPlace == () || toPlace == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
        }

        // Mock logic
        // Details of the airline
        json flightDetails = {
            "Airline":"Emirates",
            "ArrivalDate":arrivalDate,
            "ReturnDate":departureDate,
            "From":fromPlace,
            "To":toPlace,
            "Price":273
        };
        // Response payload
        response.setJsonPayload(untaint flightDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }
}
