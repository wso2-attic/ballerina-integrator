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
//    name:"car_rental_service",
//    tag:"v1.0"
//}
//
//@docker:Expose{}

//@kubernetes:Ingress {
//  hostname:"ballerina.guides.io",
//  name:"ballerina-guides-car-rental-service",
//  path:"/"
//}
//
//@kubernetes:Service {
//  serviceType:"NodePort",
//  name:"ballerina-guides-car-rental-service"
//}
//
//@kubernetes:Deployment {
//  image:"ballerina.guides.io/car_rental_service:v1.0",
//  name:"ballerina-guides-car-rental-service"
//}

// Service endpoint
listener http:Listener carEP = new (9093);

// Car rental service
@http:ServiceConfig {basePath:"/car"}
service carRentalService on carEP {

    // Resource 'driveSg', which checks about hotel 'DriveSg'
    @http:ResourceConfig {methods:["POST"], path:"/driveSg", consumes:["application/json"],
        produces:["application/json"]}
    resource function driveSg(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        json reqPayload = {};

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
        json vehicleType = reqPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || vehicleType == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
        }

        // Mock logic
        // Details of the vehicle
        json vehicleDetails = {
            "Company":"DriveSG",
            "VehicleType":vehicleType,
            "FromDate":arrivalDate,
            "ToDate":departureDate,
            "PricePerDay":5
        };
        // Response payload
        response.setJsonPayload(untaint vehicleDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'dreamCar', which checks about hotel 'DreamCar'
    @http:ResourceConfig {methods:["POST"], path:"/dreamCar", consumes:["application/json"],
        produces:["application/json"]}
    resource function dreamCar(http:Caller caller, http:Request request) returns error? {
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
        json vehicleType = reqPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || vehicleType == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
        }

        // Mock logic
        // Details of the vehicle
        json vehicleDetails = {
            "Company":"DreamCar",
            "VehicleType":vehicleType,
            "FromDate":arrivalDate,
            "ToDate":departureDate,
            "PricePerDay":6
        };
        // Response payload
        response.setJsonPayload(untaint vehicleDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }

    // Resource 'sixt', which checks about hotel 'Sixt'
    @http:ResourceConfig {methods:["POST"], path:"/sixt", consumes:["application/json"],
        produces:["application/json"]}
    resource function sixt(http:Caller caller, http:Request request) returns error? {
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
        json vehicleType = reqPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == () || departureDate == () || vehicleType == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = check caller->respond(response);
            return;
        }

        // Mock logic
        // Details of the vehicle
        json vehicleDetails = {
            "Company":"Sixt",
            "VehicleType":vehicleType,
            "FromDate":arrivalDate,
            "ToDate":departureDate,
            "PricePerDay":7
        };
        // Response payload
        response.setJsonPayload(untaint vehicleDetails);
        // Send the response to the caller
        _ = check caller->respond(response);
        return;
    }
}
