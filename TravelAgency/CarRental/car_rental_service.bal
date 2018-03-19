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

package TravelAgency.CarRental;

import ballerina.net.http;

// Car rental service
@http:configuration {basePath:"/car", port:9093}
service<http> carRentalService {

    // Resource 'driveSg', which checks about hotel 'DriveSg'
    @http:resourceConfig {methods:["POST"], path:"/driveSg", consumes:["application/json"],
                          produces:["application/json"]}
    resource driveSg (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        // Try parsing the JSON payload from the request
        json receivedPayload = inRequest.getJsonPayload();
        json arrivalDate = receivedPayload.ArrivalDate;
        json departureDate = receivedPayload.DepartureDate;
        json vehicleType = receivedPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || vehicleType == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
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
        outResponse.setJsonPayload(vehicleDetails);
        // Send the response to the client
        _ = connection.respond(outResponse);
    }

    // Resource 'dreamCar', which checks about hotel 'DreamCar'
    @http:resourceConfig {methods:["POST"], path:"/dreamCar", consumes:["application/json"],
                          produces:["application/json"]}
    resource dreamCar (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        // Try parsing the JSON payload from the request
        json receivedPayload = inRequest.getJsonPayload();
        json arrivalDate = receivedPayload.ArrivalDate;
        json departureDate = receivedPayload.DepartureDate;
        json vehicleType = receivedPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || vehicleType == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
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
        outResponse.setJsonPayload(vehicleDetails);
        // Send the response to the client
        _ = connection.respond(outResponse);
    }

    // Resource 'sixt', which checks about hotel 'Sixt'
    @http:resourceConfig {methods:["POST"], path:"/sixt", consumes:["application/json"], produces:["application/json"]}
    resource sixt (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        // Try parsing the JSON payload from the request
        json receivedPayload = inRequest.getJsonPayload();
        json arrivalDate = receivedPayload.ArrivalDate;
        json departureDate = receivedPayload.DepartureDate;
        json vehicleType = receivedPayload.VehicleType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || vehicleType == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
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
        outResponse.setJsonPayload(vehicleDetails);
        // Send the response to the client
        _ = connection.respond(outResponse);
    }
}
