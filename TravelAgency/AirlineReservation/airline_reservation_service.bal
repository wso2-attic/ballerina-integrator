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

package TravelAgency.AirlineReservation;

import ballerina.net.http;

// Available flight classes
const string ECONOMY = "Economy";
const string BUSINESS = "Business";
const string FIRST = "First";

// Airline reservation service to reserve airline tickets
@http:configuration {basePath:"/airline", port:9091}
service<http> airlineReservationService {

    // Resource to reserve a ticket
    @http:resourceConfig {methods:["POST"], path:"/reserve", consumes:["application/json"],
                          produces:["application/json"]}
    resource reserveTicket (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};

        // Try parsing the JSON payload from the request
        json payload = request.getJsonPayload();
        json name = payload.Name;
        json arrivalDate = payload.ArrivalDate;
        json departureDate = payload.DepartureDate;
        json preferredClass = payload.Preference;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || arrivalDate == null || departureDate == null || preferredClass == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available flight class, send a reservation successful status
        string preferredClassStr = preferredClass.toString().trim();
        if (preferredClassStr.equalsIgnoreCase(ECONOMY) || preferredClassStr.equalsIgnoreCase(BUSINESS) ||
            preferredClassStr.equalsIgnoreCase(FIRST)) {
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available flight class, send a reservation failure status
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
