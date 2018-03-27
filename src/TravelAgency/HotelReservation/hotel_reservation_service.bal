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

// Available room types
const string AC = "Air Conditioned";
const string NORMAL = "Normal";

// Service endpoint
endpoint http:ServiceEndpoint hotelEP {
    port:9092
};

// Hotel reservation service to reserve hotel rooms
@http:serviceConfig {basePath:"/hotel"}
service<http:Service> hotelReservationService bind hotelEP {

    // Resource to reserve a room
    @http:resourceConfig {methods:["POST"], path:"/reserve", consumes:["application/json"],
                          produces:["application/json"]}
    reserveRoom (endpoint client, http:Request request) {
        http:Response response = {};
        json name;
        json arrivalDate;
        json departDate;
        json preferredType;

        // Try parsing the JSON payload from the request
        var payload, entityErr = request.getJsonPayload();
        if(payload != null) {
            name = payload.Name;
            arrivalDate = payload.ArrivalDate;
            departDate = payload.DepartureDate;
            preferredType = payload.Preference;
        }

        // If payload parsing fails, send a "Bad Request" message as the response
        if (entityErr != null || name == null || arrivalDate == null || departDate == null || preferredType == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(response);
            return;
        }

        // Mock logic
        // If request is for an available room type, send a reservation successful status
        string preferredTypeStr = preferredType.toString().trim();
        if (preferredTypeStr.equalsIgnoreCase(AC) || preferredTypeStr.equalsIgnoreCase(NORMAL)) {
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available room type, send a reservation failure status
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = client -> respond(response);
    }
}
