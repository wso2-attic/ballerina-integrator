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

http:Client reservationEP = new ("http://localhost:8081/reservation");
http:Client paymentEP = new("http://localhost:8082/payment");

@http:ServiceConfig {
    basePath: "/doctorAppoinment"
}
service doctorAppoinment on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/reservation"
    }
    resource function makeReservation(http:Caller caller, http:Request request) {
        json requestPaylod = checkpanic request.getJsonPayload();
        json finalResponsePayload = {
            "appointment_status": "failure",
            "name":checkpanic requestPaylod.name,
            "doctor":checkpanic requestPaylod.doctor,
            "date":checkpanic requestPaylod.date
        };
        http:Response response = checkpanic reservationEP->post("/createAppointment", request);
        json appointmentResPayload = checkpanic response.getJsonPayload();
        if (appointmentResPayload.appointmentId is json) {
            json paymentReqPayload = {
                "name":checkpanic requestPaylod.name,
                "cardNum":checkpanic requestPaylod.cardNum,
                "amount":checkpanic appointmentResPayload.fee
            };
            request.setJsonPayload(<@untainted>paymentReqPayload);
            response = checkpanic paymentEP->post("/makePayment", request);
            json paymentResPayload = checkpanic response.getJsonPayload();
            finalResponsePayload = checkpanic paymentResPayload.mergeJson(appointmentResPayload);
        }
        response.setJsonPayload(<@untainted>finalResponsePayload);
        error? respond = caller->respond(response);
    }
}
