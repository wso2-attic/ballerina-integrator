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

// Service endpoint
listener http:Listener airlineEP = new(9091);

// Available flight classes
final string ECONOMY = "Economy";
final string BUSINESS = "Business";
final string FIRST = "First";

// Airline reservation service to reserve airline tickets
@http:ServiceConfig {basePath:"/airline"}
service airlineReservationService on airlineEP {

    // Resource to reserve a ticket
    @http:ResourceConfig {methods:["POST"], path:"/reserve", consumes:["application/json"],
        produces:["application/json"]}
    resource function reserveTicket(http:Caller caller, http:Request request) {
        http:Response response = new;
        json reqPayload = {};
        var payload = request.getJsonPayload();
        // Try parsing the JSON payload from the request
        if (payload is json) {
            // Valid JSON payload
            reqPayload = payload;
        } else {
            // NOT a valid JSON payload
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
            var result = caller->respond(response);
            handleError(result);
            return;
        }

        json name = checkpanic reqPayload.Name;
        json arrivalDate = checkpanic reqPayload.ArrivalDate;
        json departDate = checkpanic reqPayload.DepartureDate;
        json preferredClass = checkpanic reqPayload.Preference;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == () || arrivalDate == () || departDate == () || preferredClass == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            var result = caller->respond(response);
            handleError(result);
            return;
        }

        // Mock logic
        // If request is for an available flight class, send a reservation successful status
        string preferredClassStr = preferredClass.toString();
        if (equalIgnoreCase(preferredClassStr, ECONOMY) || equalIgnoreCase(preferredClassStr, BUSINESS) ||
            equalIgnoreCase(preferredClassStr, FIRST)) {
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available flight class, send a reservation failure status
            response.setJsonPayload({"Status":"Failed"});
        }

        // Send the response
        var result = caller->respond(response);
        handleError(result);
    }

}

