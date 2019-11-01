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

http:Client desktopAppointmentEP = new("http://localhost:9092/appointmentMgt");
http:Client desktopMedicalRecordEP = new("http://localhost:9093/recordMgt");
http:Client desktopNotificationEP = new("http://localhost:9094/notificationMgt");
http:Client desktopMessageEP = new("http://localhost:9095/messageMgt");

@http:ServiceConfig {
    basePath: "/desktop"
}
service desktop_bff_service on new http:Listener(9091) {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/alerts"
    }
    resource function getAlerts(http:Caller caller, http:Request req) {

        http:Response notificationResponse = checkpanic desktopNotificationEP->get("/list");        
        http:Response messageResponse = checkpanic desktopMessageEP->get("/list");
        json notificationList = checkpanic notificationResponse.getJsonPayload();
        json messageList = checkpanic messageResponse.getJsonPayload();
        map<json> alertJsonMap = {};       
        alertJsonMap["Notifications"] = notificationList; 
        alertJsonMap["Messages"] = messageList;        
        json alertJson = <json> map<json>.constructFrom(alertJsonMap);
        http:Response response = new;
        response.setJsonPayload(<@untainted> alertJson);
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments"
    }
    resource function getAppointments(http:Caller caller, http:Request req) {
        http:Response appointmentResponse = checkpanic desktopAppointmentEP->get("/list");
        json appointmentList = checkpanic appointmentResponse.getJsonPayload();
        map<json>|error appointmentListMap = map<json>.constructFrom(appointmentList);
        http:Response response = new();
        response.setJsonPayload(<@untainted> appointmentList);
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/medicalRecords"
    }
    resource function getMedicalRecords(http:Caller caller, http:Request req) {
        http:Response recordResponse = checkpanic desktopMedicalRecordEP->get("/list");
        json medicalRecordList = checkpanic recordResponse.getJsonPayload();        
        http:Response response = new();
        response.setJsonPayload(<@untainted> medicalRecordList);
        checkpanic caller->respond(response);
    }
}
