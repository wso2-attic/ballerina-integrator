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

import ballerina/io;
import ballerina/log;
import daos;
import util;

# Reserve appointment from appointment request.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
# + category - Category want to reserve appointment
function reserveAppointment(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string category) {
    json|error jsonRequestPayload = req.getJsonPayload();
    if (jsonRequestPayload is json) {
        // Convert request payload to AppointmentRequest record.
        daos:AppointmentRequest | error appointmentRequest = daos:AppointmentRequest.convert(jsonRequestPayload);

        if (appointmentRequest is daos:AppointmentRequest) {
            // Check whether given category is available.
            if (util:containsStringElement(<string[]>hospitalDao["categories"], category)) {
                // Make new appointment.
                daos:Appointment | error appointment = util:makeNewAppointment(appointmentRequest, hospitalDao);

                if (appointment is daos:Appointment) {
                    // Add made appointment in to appointments map.
                    HealthcareService
                        .appointments[string.convert(<int>appointment["appointmentNumber"])] = appointment;
                    // Add patient to the patient map.
                    hospitalDao["patientMap"][<string>appointmentRequest["patient"]["ssn"]] = 
                                                                    <daos:Patient>appointmentRequest["patient"];
                    // Add patient to patient record map.
                    map<daos:PatientRecord> patientRecordMap =  
                                                    <map<daos:PatientRecord>> hospitalDao["patientRecordMap"];
                    // If patient is not in the patient record map add patient to record map.
                    if (!(util:containsInPatientRecordMap(patientRecordMap, 
                                                                <string>appointmentRequest["patient"]["ssn"]))) {
                        daos:PatientRecord pr = {
                            patient: <daos:Patient>appointmentRequest["patient"],
                            symptoms: {},
                            treatments: {}
                        };
                        hospitalDao["patientRecordMap"][<string>appointmentRequest["patient"]["ssn"]] = pr;
                    }

                    // Convert appointment record to json.
                    json | error appointmentJson = json.convert(appointment);
                    if (appointmentJson is json) {
                        util:sendResponse(caller, appointmentJson);
                    } else {
                        log:printError("Error occurred when converting appointment record to JSON.", 
                                                    err = appointmentJson);
                        util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                    statusCode = http:INTERNAL_SERVER_ERROR_500);
                    }
                } else {
                    string doctorNotAvailable = "Doctor " + <string>appointmentRequest["doctor"]
                    + " is not available in " + <string>appointmentRequest["hospital"];
                    log:printInfo("User error when reserving appointment: " + doctorNotAvailable);
                    util:sendResponse(caller, json.convert(doctorNotAvailable), statusCode = 400);
                }
            } else {
                string invalidCategory = "Invalid category: " + category;
                log:printInfo("User error when reserving appointment: " + invalidCategory);
                util:sendResponse(caller, json.convert(invalidCategory), statusCode = 400);
            }
        } else {
            log:printError("Could not convert recieved payload to AppointmentRequest record.", 
                                                                                    err = appointmentRequest);
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    } else {
        util:sendResponse(caller, json.convert("Invalid payload received"), statusCode = 400);
    }
}

# Get appointment for a given appointment number.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need the get the appointment
function getAppointment(http:Caller caller, http:Request req, int appointmentNo) {
    // Get appoitment from appointments map using appointment number.
    var appointment = HealthcareService.appointments[string.convert(appointmentNo)];

    if (appointment is daos:Appointment) {
        // Convert appointment record to json.
        json|error appointmentJson = json.convert(appointment);

        if (appointmentJson is json) {
            util:sendResponse(caller, appointmentJson);
        } else {
            log:printError("Error occurred when converting appointment record to JSON.", err = appointmentJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in getAppointment, Invalid appointment number: " + appointmentNo);
        util:sendResponse(caller, "Invalid appointment number.", statusCode = 400);
    }
}

# Check channeling fee for a given appointment number.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need to check channeling fee
function checkChannellingFee(http:Caller caller, http:Request req, int appointmentNo) {
    // Check whether there is an appointment with the given appointment number.
    if (util:containsAppointmentId(HealthcareService.appointments, string.convert(appointmentNo))) {
        daos:Patient patient = 
                        <daos:Patient>HealthcareService.appointments[string.convert(appointmentNo)]["patient"];
        daos:Doctor doctor = <daos:Doctor>HealthcareService.appointments[string.convert(appointmentNo)]["doctor"];

        // Create channeling fee record.
        daos:ChannelingFee channelingFee = {
            patientName: <string>patient["name"],
            doctorName: <string>doctor["name"],
            actualFee: string.convert(<float>doctor["fee"])
        };

        // Convert channeling fee record to json.
        json|error channelingFeeJson = json.convert(channelingFee);
        if (channelingFeeJson is json) {
            util:sendResponse(caller, channelingFeeJson);
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", 
                                                                                    err = channelingFeeJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in checkChannellingFee, Could not Find the Requested appointment ID: " 
                                                                                            + appointmentNo);
        util:sendResponse(caller, "Error. Could not Find the Requested appointment ID.", statusCode = 400);
    }
}

# Update patient record with symptoms and treatments.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
function updatePatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    json|error patientDetails = req.getJsonPayload();

    if (patientDetails is json) {
        string ssn = <string>patientDetails["ssn"];
        // Validate symptoms and treatments in the request.
        if ((patientDetails["symptoms"] is json[]) && (patientDetails["treatments"] is json[])) {
            string[] symptoms = util:convertJsonToStringArray(<json[]>patientDetails["symptoms"]);
            string[] treatments = util:convertJsonToStringArray(<json[]>patientDetails["treatments"]);

            // Get the patient from patients map.
            var patient = hospitalDao["patientMap"][ssn];
            if (patient is daos:Patient) {
                // Get the patient record from patient record map.
                var patientRecord = hospitalDao["patientRecordMap"][ssn];
                if (patientRecord is daos:PatientRecord) {
                    // Update symptoms and treatments in the patient record.
                    if (daos:updateSymptomsInPatientRecord(patientRecord, symptoms)
                                            && daos:updateTreatmentsInPatientRecord(patientRecord, treatments)) {
                        util:sendResponse(caller, "Record Update Success.");
                    } else {
                        log:printError("Record Update Failed when updating patient record. "
                                                + "updateSymptomsInPatientRecord: "
                                                + daos:updateSymptomsInPatientRecord(patientRecord, symptoms)
                                                + "updateTreatmentsInPatientRecord: "
                                                + daos:updateTreatmentsInPatientRecord(patientRecord, symptoms));
                        util:sendResponse(caller, "Record Update Failed.", 
                                                                statusCode = http:INTERNAL_SERVER_ERROR_500);
                    }
                } else {
                    log:printInfo("User error when updating patient record, Could not find valid Patient Record.");
                    util:sendResponse(caller, "Could not find valid Patient Record.", statusCode = 400);
                }
            } else {
                log:printInfo("User error when updating patient record, Could not find valid Patient Entry.");
                util:sendResponse(caller, "Could not find valid Patient Entry.", statusCode = 400);
            }
        } else {
            log:printInfo("User error when updating patient record, Invalid payload received.");
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    } else {
        log:printInfo("User error when updating patient record, Invalid payload received.");
        util:sendResponse(caller, "Invalid payload received", statusCode = 400);
    }
}

# Get patient record from the given ssn.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
# + ssn - Patient's ssn number
function getPatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string ssn) {
    var patientRecord = hospitalDao["patientRecordMap"][ssn];

    if (patientRecord is daos:PatientRecord) {
        // Convert patient record in to json.
        json|error patientRecordJson = json.convert(patientRecord);
        if (patientRecordJson is json) {
            util:sendResponse(caller, patientRecordJson);
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", 
                                                                                err = patientRecordJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in getPatientRecord, Could not find valid Patient Entry.");
        util:sendResponse(caller, "Could not find valid Patient Entry.", statusCode = 400);
    }
}

# Check whether patient in the appoinment eligible for discounts.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need to check the eligibility for discounts.
function isEligibleForDiscount(http:Caller caller, http:Request req, int appointmentNo) {
    // Get the relevant appointment from the appointments map.
    var appointment = HealthcareService.appointments[string.convert(appointmentNo)];

    if (appointment is daos:Appointment) {
        boolean|error eligible = util:checkDiscountEligibility(<string>appointment["patient"]["dob"]);
        if (eligible is boolean) {
            util:sendResponse(caller, eligible);
        } else {
            log:printError("Error occurred when checking discount eligibility.", err = eligible);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in isEligibleForDiscount, Invalid appointment ID: " + appointmentNo);
        util:sendResponse(caller, "Invalid appointment ID.", statusCode = 400);
    }
}

# Add new doctor to the hospital.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
function addNewDoctor(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    var doctorDetails = req.getJsonPayload();

    if (doctorDetails is json) {
        // Create doctor record from request payload.
        daos:Doctor|error doc = daos:Doctor.convert(doctorDetails);
        
        if(doc is daos:Doctor) {
            string category = <string>doc["category"];
            // If new doctor's category is not exists in hospital categories add it to it.
            if (!(util:containsStringElement(<string[]>hospitalDao["categories"], category))) {
                string[] tempArr = <string[]>hospitalDao["categories"];
                tempArr[tempArr.length()] = category;
                hospitalDao["categories"] = tempArr;
            }

            // Check whether same doctor already added.
            daos:Doctor|error doctor = daos:findDoctorByName(untaint hospitalDao, <string>doctorDetails["name"]);
            if (doctor is daos:Doctor) {
                log:printInfo("User error in addNewDoctor, Doctor Already Exists in the system.");
                util:sendResponse(caller, "Doctor Already Exists in the system.", statusCode = 400);
            } else {
                // Add new doctor to the hospital.
                hospitalDao["doctorsList"][<int>hospitalDao["doctorsList"].length()] = doc;
                util:sendResponse(caller, "New Doctor Added Successfully.");
            }
        } else {
            log:printError("Could not convert recieved payload to Doctor record.", err = doc);
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    } else {
        log:printInfo("User error when adding a new doctor: Invalid payload received.");
        util:sendResponse(caller, "Invalid payload received", statusCode = 400);
    }
}
