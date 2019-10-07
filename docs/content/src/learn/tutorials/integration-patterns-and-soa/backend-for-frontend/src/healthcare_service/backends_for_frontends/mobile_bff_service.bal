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

http:Client mobileAppointmentEP = new ("http://localhost:9092/appointmentMgt");
http:Client mobileMedicalRecordEP = new ("http://localhost:9093/recordMgt");
http:Client mobileMessageEP = new ("http://localhost:9095/messageMgt");

// RESTful service.
@http:ServiceConfig {
    basePath: "/mobile"
}
service mobile_bff_service on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/data"
    }
    resource function getAppData(http:Caller caller, http:Request req) {

        http:Response appointmentResponse = checkpanic mobileAppointmentEP->get("/list");
        json appointmentList = checkpanic appointmentResponse.getJsonPayload();

        http:Response reportResponse = checkpanic mobileMedicalRecordEP->get("/list");
        json medicalRecordList = checkpanic reportResponse.getJsonPayload();

        http:Response messageResponse = checkpanic mobileMessageEP->get("/list");
        json messageList = checkpanic messageResponse.getJsonPayload();

        map<json> profileJsonMap = {};
        profileJsonMap["Appointments"] = appointmentList;
        profileJsonMap["Messages"] = medicalRecordList;
        profileJsonMap["MedicalRecords"] = messageList;
        json profileJson = <json>map<json>.constructFrom(profileJsonMap);
        http:Response response = new ();
        response.setJsonPayload(<@untainted> profileJson);
        checkpanic caller->respond(response);
    }
}
