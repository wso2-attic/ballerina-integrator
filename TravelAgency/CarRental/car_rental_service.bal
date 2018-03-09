
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
import ballerina.log;

// Available car types
const string AC = "Air Conditioned";
const string NORMAL = "Normal";

// Car rental service to rent cars
@http:configuration {basePath:"/car", port:9093}
service<http> carRentalService {

    // Resource to rent a car
    @http:resourceConfig {methods:["POST"], path:"/rent"}
    resource rentCar (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};
        string name;
        string arrivalDate;
        string departureDate;
        string preferredType;

        // Try parsing the JSON payload from the request
        try {
            json payload = request.getJsonPayload();
            name = payload.Name.toString();
            arrivalDate = payload.ArrivalDate.toString();
            departureDate = payload.DepartureDate.toString();
            preferredType = payload.Preference.toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available car type, send a rental successful status
        if (preferredType.equalsIgnoreCase(AC) || preferredType.equalsIgnoreCase(NORMAL)) {
            log:printInfo("Successfully rented car for user: " + name);
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available car type, send a rental failure status
            log:printWarn("Failed to reserve rent car for user: " + name);
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
