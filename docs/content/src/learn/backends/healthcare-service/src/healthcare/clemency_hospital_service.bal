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

Doctor doctorClemency1 = {
    name: "anne clement",
    hospital: "clemency medical center",
    category: "surgery",
    availability: "8.00 a.m - 10.00 a.m",
    fee: 12000
};

Doctor doctorClemency2 = {
    name: "thomas kirk",
    hospital: "clemency medical center",
    category: "gynaecology",
    availability: "9.00 a.m - 11.00 a.m",
    fee: 8000
};

Doctor doctorClemency3 = {
    name: "cailen cooper",
    hospital: "clemency medical center",
    category: "paediatric",
    availability: "9.00 a.m - 11.00 a.m",
    fee: 5500
};

HospitalDAO clemencyHospitalDao = {
    doctorsList: [doctorClemency1, doctorClemency2, doctorClemency3],
    categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
    patientMap: {},
    patientRecordMap: {}
};

@http:ServiceConfig {
    basePath: "/clemency/categories"
}
service ClemencyHospitalService on httpListener {
    // Reserve appointment from appointment request.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{category}/reserve"
    }
    resource function reserveAppointment(http:Caller caller, http:Request req, string category) {
        HospitalDAO hospitalDao = <@untainted> clemencyHospitalDao;
        reserveAppointment(caller, req, hospitalDao, category);
    }

    // Get appointment for a given appointment number.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        getAppointment(caller, req, appointmentId);
    }

    // Check channeling fee for a given appointment number.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}/fee"
    }
    resource function checkChannellingFee(http:Caller caller, http:Request req, int appointmentId) {
        checkChannellingFee(caller, req, appointmentId);
    }

    // Update patient record with symptoms and treatments.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/patient/updaterecord"
    }
    resource function updatePatientRecord(http:Caller caller, http:Request req) {
        updatePatientRecord(caller, req, clemencyHospitalDao);
    }

    // Get patient record from the given ssn.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/{ssn}/getrecord"
    }
    resource function getPatientRecord(http:Caller caller, http:Request req, string ssn) {
        getPatientRecord(caller, req, clemencyHospitalDao, ssn);
    }

    // Check whether patient in the appoinment eligible for discounts.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/appointment/{appointmentId}/discount"
    }
    resource function isEligibleForDiscount(http:Caller caller, http:Request req, int appointmentId) {
        isEligibleForDiscount(caller, req, appointmentId);
    }

    // Add new doctor to the hospital.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/doctor/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) {
        HospitalDAO hospitalDao = <@untainted> clemencyHospitalDao;
        addNewDoctor(caller, req, hospitalDao);
    }
}
