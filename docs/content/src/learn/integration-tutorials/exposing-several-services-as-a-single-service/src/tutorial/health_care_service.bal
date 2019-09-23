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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

// hospital service endpoint
http:Client hospitalEP = new("http://localhost:9095");

const string GRAND_OAK = "grand oak community hospital";
const string CLEMENCY = "clemency medical center";
const string PINE_VALLEY = "pine valley community hospital";
json finalPayload = "";

@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on new http:Listener(9092) {
    // Resource to make an appointment reservation with bill payment
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function scheduleAppointment(http:Caller caller, http:Request request, string category) {
        var requestDataset = request.getJsonPayload();
        if (requestDataset is json) {
            // tranform the request payload to the format expected by the backend end service
            json reservationPayload = {
                "patient": {
                    "name": <json>requestDataset.name,
                    "dob": <json>requestDataset.dob,
                    "ssn": <json>requestDataset.ssn,
                    "address": <json>requestDataset.address,
                    "phone": <json>requestDataset.phone,
                    "email": <json>requestDataset.email
                },
                "doctor": <json>requestDataset.doctor,
                "hospital": <json>requestDataset.hospital,
                "appointmentDate": <json>requestDataset.appointmentDate
            };
            // call appointment creation
            // CODE-SEGMENT-BEGIN: segment_2
            http:Response reservationResponse = createAppointment(caller, <@untainted> reservationPayload, category);
            // CODE-SEGMENT-END: segment_2

            json | error responsePayload = reservationResponse.getJsonPayload();
            if (responsePayload is json) {
                // Convert json to map of json
                map<json>|error responsePayloadMap = map<json>.constructFrom(responsePayload);
                if(responsePayloadMap is map<json>)
                {
                    // add cardNo to the response payload
                    responsePayloadMap["cardNumber"] = <json>requestDataset.cardNo;
                    finalPayload = <json>json.constructFrom(<@untainted> responsePayloadMap);
                }

                // check if the json payload is actually an appointment confirmation response
                if (finalPayload.appointmentNumber is ()) {
                    respondToClient(caller, createErrorResponse(500, <@untainted> responsePayload.toString()));
                    return;
                }

                // // add cardNo to the response payload
                // responsePayload["cardNumber"] = requestDataset.cardNo;

                http:Response paymentResponse = doPayment(<@untainted> <json>finalPayload);
                // send the response back to the client
                respondToClient(caller, paymentResponse);
            } else {
                respondToClient(caller, createErrorResponse(500, "Backend did not respond with json"));
            }
        } else {
            respondToClient(caller, createErrorResponse(400, "Not a valid Json payload"));
        }
    }
}

// function to call hospital service backend and make an appointment reservation
// CODE-SEGMENT-BEGIN: segment_1
function createAppointment(http:Caller caller, json payload, string category) returns http:Response {
    string hospitalName = payload.hospital.toString();
    http:Request reservationRequest = new;
    reservationRequest.setPayload(payload);
    http:Response | error reservationResponse = new;
    match hospitalName {
        GRAND_OAK => {
            reservationResponse = hospitalEP->
            post("/grandoaks/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        CLEMENCY => {
            reservationResponse = hospitalEP->
            post("/clemency/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        PINE_VALLEY => {
            reservationResponse = hospitalEP->
            post("/pinevalley/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        _ => {
            respondToClient(caller, createErrorResponse(500, "Unknown hospital name"));
        }
    }
    return handleResponse(reservationResponse);
}
// CODE-SEGMENT-END: segment_1

// function to call hospital service backend and make payment for an appointment reservation
// CODE-SEGMENT-BEGIN: segment_3
function doPayment(json payload) returns http:Response {
    http:Request paymentRequest = new;
    paymentRequest.setPayload(payload);
    http:Response | error paymentResponse = hospitalEP->post("/healthcare/payments", paymentRequest);
    return handleResponse(paymentResponse);
}
// CODE-SEGMENT-END: segment_3

// util method to handle response
function handleResponse(http:Response | error response) returns http:Response {
    if (response is http:Response) {
        return response;
    } else {
        return createErrorResponse(500, <string> response.toString());
    }
}

//util method to respond to a caller and handle error
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}

// util method to create error response
function createErrorResponse(int statusCode, string msg) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = statusCode;
    errorResponse.setPayload(msg);
    return errorResponse;
}
