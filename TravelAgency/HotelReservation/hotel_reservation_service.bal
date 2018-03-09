
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

package TravelAgency.HotelReservation;

import ballerina.net.http;
import ballerina.log;

// Available room types
const string AC = "Air Conditioned";
const string NORMAL = "Normal";

// Hotel reservation service to reserve hotel rooms
@http:configuration {basePath:"/hotel", port:9092}
service<http> hotelReservationService {

    // Resource to reserve a room
    @http:resourceConfig {methods:["POST"], path:"/reserve"}
    resource reserveRoom (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};
        string name;
        string arrivalDate;
        string departureDate;
        string preferredRoomType;

        // Try parsing the JSON payload from the request
        try {
            json payload = request.getJsonPayload();
            name = payload.Name.toString();
            arrivalDate = payload.ArrivalDate.toString();
            departureDate = payload.DepartureDate.toString();
            preferredRoomType = payload.Preference.toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available room type, send a reservation successful status
        if (preferredRoomType.equalsIgnoreCase(AC) || preferredRoomType.equalsIgnoreCase(NORMAL)) {
            log:printInfo("Successfully reserved hotel room for user: " + name);
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available room type, send a reservation failure status
            log:printWarn("Failed to reserve hotel room for user: " + name);
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
