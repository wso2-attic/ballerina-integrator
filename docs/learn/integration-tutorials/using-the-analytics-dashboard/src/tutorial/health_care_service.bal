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
import ballerina/io;
import ballerina/test;

// hospital service endpoint
http:Client hospitalEP = new("http://localhost:9095");

@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service hospitalMgtService on new http:Listener(9092) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/analytics"
    }
    resource function runSampleQueries(http:Caller caller, http:Request req) {
        string hospital = "grandoaks";
        string categoryName = "surgery";

        // get doctors in a category
        string[] categories = ["surgery", "cardiology", "gynaecology", "ent", "paediatric"];
        foreach var category in categories {
            getDoctorsInCategory(category);
        }

        // schedule appointment
        json appointmentPayload = {
        "patient": {
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": "johndoe@gmail.com"
        },
        "doctor": "thomas collins",
        "hospital": "grand oak community hospital",
        "appointmentDate": "2025-04-02"
        };
        scheduleAppointment(appointmentPayload, hospital, categoryName);

        // get appointment with id
        int appointmentId = 1;
        getAppointmentWithId(appointmentId, hospital);

        // check appointemnt validity with id
        checkAppointmentValidity(appointmentId);

        // check appointment fee with id
        checkAppointmentFee(appointmentId, hospital);

        // get patient details
        string patientSsn = "234-23-525";
        getPatientDetails(patientSsn, hospital);

        // update patient details
        json updatePatientJson = {
            "symptoms": ["Cough"],
            "treatments": ["Panadol"],
            "ssn": "234-23-525"
        };
        updatePatientDetails(updatePatientJson, hospital);

        // get discount eligibility
        getDiscountEligibility(appointmentId, hospital);

        // add new doctor
        json doctorJson = {
            "name": "susan clement",
            "hospital": "grand oak community hospital",
            "category": "surgery",
            "availability": "9.00 a.m - 12.00 a.m",
            "fee": 12000.00
        };
        addNewDoctor(doctorJson);

        var result = caller->respond("Completed running functions");
    }
}

// CODE-SEGMENT-BEGIN: segment_1
// Get doctors in a category
function getDoctorsInCategory(string category) {
    log:printInfo("Querying doctors in category: " + category);
    http:Response | error response = hospitalEP->get("/healthcare/queryDoctor/" + category);
    handleResponse(response);
}
// CODE-SEGMENT-END: segment_1

// Schedule an appointment
function scheduleAppointment(json payload, string hospital, string category) {
    log:printInfo("Scheduling appointment at: " + hospital + " for: " + category);
    string endpointName = "/" + hospital + "/categories/" + category + "/reserve";
    http:Response | error response = hospitalEP->post(endpointName, payload);
    handleResponse(response);
}

// Get appointment with appointment number
function getAppointmentWithId(int id, string hospital) {
    log:printInfo("Retrieving appointment no: " + id.toString());
    http:Response | error response = hospitalEP->get("/" + hospital + "/categories/appointments/" + id.toString());
    handleResponse(response);
}

// Check appointment validity with appointment number
function checkAppointmentValidity(int id) {
    log:printInfo("Checking validity of appointment no: " + id.toString());
    http:Response | error response = hospitalEP->get("/healthcare/appointments/validity/" + id.toString());
    handleResponse(response);
}

// Check appointment fee with appointment number
function checkAppointmentFee(int id, string hospital) {
    log:printInfo("Checking fee for appointment no: " + id.toString());
    http:Response | error response = hospitalEP->get("/" + hospital + "/categories/appointments/" + id.toString() + "/fee");
    handleResponse(response);
}

// Get patient details
function getPatientDetails(string ssn, string hospital) {
    log:printInfo("Retrieving patient with ssn: " + ssn);
    http:Response | error response = hospitalEP->get("/" + hospital + "/categories/patient/" + ssn + "/getrecord");
    handleResponse(response);
}

// Update patient details
function updatePatientDetails(json patient, string hospital) {
    log:printInfo("Updating patient with ssn: " + patient.ssn.toString());
    http:Response | error response = hospitalEP->post("/" + hospital + "/categories/patient/updaterecord/", patient);
    handleResponse(response);
}

// Get eligibility for discount
function getDiscountEligibility(int id, string hospital) {
    log:printInfo("Checking eligibility for discount for appointment: " + id.toString());
    http:Response | error response = hospitalEP->get("/" + hospital + "/categories/patient/appointment/" + id.toString() + "/discount");
    handleResponse(response);
}

// Add new doctor
function addNewDoctor(json doctorJson) {
    log:printInfo("Adding new doctor at: " + doctorJson.hospital.toString());
    http:Response | error response = hospitalEP->post("/healthcare/admin/newdoctor", doctorJson);
    handleResponse(response);
}

function handleResponse(http:Response|error response){
    if (response is http:Response) {
        string|error textPayload = response.getTextPayload();
        if(textPayload is string){
            log:printInfo(textPayload);
        }
        else{
            log:printInfo("Error in response.");
        }
    }
    else {
        log:printInfo("Error in response.");
    }
}


