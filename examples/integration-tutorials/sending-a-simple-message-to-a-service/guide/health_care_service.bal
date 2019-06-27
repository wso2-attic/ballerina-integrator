// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

// CODE-SEGMENT-BEGIN: segment_1
listener http:Listener httpListener = new(9090);
// CODE-SEGMENT-END: segment_1
// CODE-SEGMENT-BEGIN: segment_4
http:Client healthcareEndpoint = new("http://localhost:9091/healthcare");
// CODE-SEGMENT-END: segment_4

// Health Care Management is done using an in-memory map.
map<json> appoinmentMap = {

};

// RESTful service.
// CODE-SEGMENT-BEGIN: segment_2
@http:ServiceConfig {
    basePath: "/hospitalmgt"
}
service hospitalMgt on httpListener
// CODE-SEGMENT-END: segment_2
{
    // CODE-SEGMENT-BEGIN: segment_3
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getdoctor/{category}"
    }
    resource function getDoctorInCategory(http:Caller caller, http:Request req, string category)
    // CODE-SEGMENT-END: segment_3
    {
        // CODE-SEGMENT-BEGIN: segment_5
        var response = healthcareEndpoint->get("/queryDoctor/" +untaint category);
        // CODE-SEGMENT-END: segment_5
        // CODE-SEGMENT-BEGIN: segment_6
        if (response is http:Response && response.getJsonPayload() is json) {
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    // CODE-SEGMENT-END: segment_6
    }

// Resource that handles the HTTP GET requests
// @http:ResourceConfig {
//     methods: ["GET"],
//     path: "/medicalreservation/{patientID}"
// }
// resource function getAppoinmentDetails(http:Caller caller, http:Request req, string patientID) {
//     // Find the requested appoinment from the map and retrieve it in JSON format.
//     json? payload = appoinmentMap[patientID];
//     http:Response response = new;
//     if (payload == null) {
//         payload = "Medical reservation : " + patientID + " cannot be found.";
//     }
//     // Set the JSON payload in the outgoing response message.
//     response.setJsonPayload(untaint payload);
//     // Send response to the client.
//     var result = caller->respond(response);
//     if (result is error) {
//         log:printError("Error sending response", err = result);
//     }
// }

// Resource that handles the HTTP POST requests
// @http:ResourceConfig {
//     methods: ["POST"],
//     path: "/medicalreservation"
// }
// resource function addAppoinmentDetails(http:Caller caller, http:Request req) {
//     http:Response response = new;
//     var patientReq = req.getJsonPayload();
//     if (patientReq is json) {
//         string patientID = patientReq.Appoinment.ID.toString();
//         appoinmentMap[patientID] = patientReq;
//         response.setJsonPayload(untaint patientReq);
//         // Set 201 Created status code in the response message.
//         response.statusCode = 201;
//         response.setHeader("Location",
//             "http://localhost:9090/hospitalmgt/medicalreservation/" + patientID);
//         // Send response to the client.
//         var result = caller->respond(response);
//         if (result is error) {
//             log:printError("Error sending response", err = result);
//         }
//     } else {
//         response.statusCode = 400;
//         response.setPayload("Invalid payload received");
//         var result = caller->respond(response);
//         if (result is error) {
//             log:printError("Error sending response", err = result);
//         }
//     }
// }

// // Resource that handles the HTTP PUT requests
// @http:ResourceConfig {
//     methods: ["PUT"],
//     path: "/medicalreservation/{patientID}"
// }
// resource function updateAppoinmentDetails(http:Caller caller, http:Request req, string patientID) {
//     var updatedAppoinment = req.getJsonPayload();
//     http:Response response = new;
//     if (updatedAppoinment is json) {
//         // Find the appoinment that needs to be updated and retrieve it in JSON format.
//         json existingAppoinment = appoinmentMap[patientID];

//         // Updating existing appoinment with the attributes of the updated appoinment.
//         if (existingAppoinment != null) {
//             existingAppoinment.Appoinment.Name = updatedAppoinment.Appoinment.Name;

//             appoinmentMap[patientID] = existingAppoinment;
//         } else {
//             existingAppoinment = "Medical reservation : " + patientID + " cannot be found.";
//         }
//         // Set the JSON payload to the outgoing response message to the client.
//         response.setJsonPayload(untaint existingAppoinment);
//         // Send response to the client.
//         var result = caller->respond(response);
//         if (result is error) {
//             log:printError("Error sending response", err = result);
//         }
//     } else {
//         response.statusCode = 400;
//         response.setPayload("Invalid payload received");
//         var result = caller->respond(response);
//         if (result is error) {
//             log:printError("Error sending response", err = result);
//         }
//     }
// }

// // Resource that handles the HTTP DELETE requests
// @http:ResourceConfig {
//     methods: ["DELETE"],
//     path: "/medicalreservation/{patientID}"
// }
// resource function cancelAppoinment(http:Caller caller, http:Request req, string patientID) {
//     http:Response response = new;
//     // Remove the requested appoinment from the map.
//     _ = appoinmentMap.remove(patientID);

//     json payload = "Medical reservation : " + patientID + " removed.";
//     // Set a generated payload with appoinment status.
//     response.setJsonPayload(untaint payload);

//     // Send response to the client.
//     var result = caller->respond(response);
//     if (result is error) {
//         log:printError("Error sending response", err = result);
//     }
// }
}
