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

package CarRental;

import ballerina/net.http;

// Available car types
const string AC = "Air Conditioned";
const string NORMAL = "Normal";

// Service endpoint
endpoint http:ServiceEndpoint carEP {
    port:9093
};

// Car rental service to rent cars
@http:ServiceConfig {basePath:"/car"}
service<http:Service> carRentalService bind carEP {

    // Resource to rent a car
    @http:ResourceConfig {methods:["POST"], path:"/rent", consumes:["application/json"], produces:["application/json"]}
    rentCar (endpoint client, http:Request request) {
        http:Response response = {};
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
        // Valid JSON payload
            json payload => reqPayload = payload;
        // NOT a valid JSON payload
            any | null => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                return;
            }
        }

        json name = reqPayload.Name;
        json arrivalDate = reqPayload.ArrivalDate;
        json departDate = reqPayload.DepartureDate;
        json preferredType = reqPayload.Preference;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || arrivalDate == null || departDate == null || preferredType == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(response);
            return;
        }

        // Mock logic
        // If request is for an available car type, send a rental successful status
        string preferredTypeStr = preferredType.toString().trim();
        if (preferredTypeStr.equalsIgnoreCase(AC) || preferredTypeStr.equalsIgnoreCase(NORMAL)) {
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available car type, send a rental failure status
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = client -> respond(response);
    }
}
