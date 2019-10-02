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
listener http:Listener hotelEP = new(9092);

// Available room types
final string AC = "Air Conditioned";
final string NORMAL = "Normal";

// Hotel reservation service to reserve hotel rooms
@http:ServiceConfig {basePath:"/hotel"}
service hotelReservationService on hotelEP {

    // Resource to reserve a room
    @http:ResourceConfig {methods:["POST"], path:"/reserve", consumes:["application/json"],
        produces:["application/json"]}
    resource function reserveRoom(http:Caller caller, http:Request request) {

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

        json|error name = reqPayload.Name;
        json|error arrivalDate = reqPayload.ArrivalDate;
        json|error departDate = reqPayload.DepartureDate;
        json|error preferredRoomType = reqPayload.Preference;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == () || arrivalDate == () || departDate == () || preferredRoomType == ()) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            var result = caller->respond(response);
            handleError(result);
            return;
        } else if (name is error || arrivalDate is error || departDate is error || preferredRoomType is error) {
            response.statusCode = 500;
            response.setJsonPayload({"Message":"Internal Server Error - Error while processing request parameters"});
            var result = caller->respond(response);
            handleError(result);
            return;
        }

        // Mock logic
        // If request is for an available room type, send a reservation successful status
        string preferredTypeStr = preferredRoomType.toString();
        if (equalIgnoreCase(preferredTypeStr, AC) || equalIgnoreCase(preferredTypeStr, NORMAL)) {
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available room type, send a reservation failure status
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        var result = caller->respond(response);
        handleError(result);
    }

}

function equalIgnoreCase(string string1, string string2) returns boolean {
    return (string1.toLowerAscii() == string2.toLowerAscii());
}
