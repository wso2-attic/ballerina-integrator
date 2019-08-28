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
import ballerina/http;

# Reserve appointment from appointment request.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
# + category - Category want to reserve appointment
function reserveAppointment(http:Caller caller, http:Request req, @tainted HospitalDAO hospitalDao, string category) {
    json|error jsonRequestPayload = req.getJsonPayload();
    if (jsonRequestPayload is json) {
        // Convert request payload to AppointmentRequest record.
        AppointmentRequest | error appointmentRequest = AppointmentRequest.constructFrom(jsonRequestPayload);

        if (appointmentRequest is AppointmentRequest) {
            // Check whether given category is available.
            if (containsStringElement(<string[]>hospitalDao["categories"], category)) {
                // Make new appointment.
                Appointment | error appointment = makeNewAppointment(appointmentRequest, hospitalDao);

                if (appointment is Appointment) {
                    // Add made appointment in to appointments map.
                    appointments[appointment["appointmentNumber"].toString()] = appointment;
                    // Add patient to the patient map.
                    hospitalDao["patientMap"][<string>appointmentRequest["patient"]["ssn"]] = 
                        <Patient>appointmentRequest["patient"];
                    // Add patient to patient record map.
                    map<PatientRecord> patientRecordMap =  <map<PatientRecord>> hospitalDao["patientRecordMap"];

                    // If patient is not in the patient record map add patient to record map.
                    if (!(containsInPatientRecordMap(patientRecordMap, <string>appointmentRequest["patient"]["ssn"]))) {
                        PatientRecord pr = {
                            patient: <Patient>appointmentRequest["patient"],
                            symptoms: {},
                            treatments: {}
                        };
                        hospitalDao["patientRecordMap"][<string>appointmentRequest["patient"]["ssn"]] = pr;
                    }

                    // constructFrom appointment record to json.
                    json | error appointmentJson = json.constructFrom(appointment);
                    if (appointmentJson is json) {
                        sendResponse(caller, appointmentJson);
                    } else {
                        log:printError("Error occurred when constructFroming appointment record to JSON.", 
                                                    err = appointmentJson);
                        sendResponse(caller, "Internal error occurred.", 
                            statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                    }
                } else {
                    string doctorNotAvailable = "Doctor " + <string>appointmentRequest["doctor"]
                    + " is not available in " + <string>appointmentRequest["hospital"];
                    log:printInfo("User error when reserving appointment: " + doctorNotAvailable);
                    sendResponse(caller, doctorNotAvailable, statusCode = http:STATUS_BAD_REQUEST);
                }
            } else {
                string invalidCategory = "Invalid category: " + category;
                log:printInfo("User error when reserving appointment: " + invalidCategory);
                sendResponse(caller, invalidCategory, statusCode = http:STATUS_BAD_REQUEST);
            }
        } else {
            log:printError("Could not convert recieved payload to AppointmentRequest record.", 
                err = appointmentRequest);
            sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Get appointment for a given appointment number.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need the get the appointment
function getAppointment(http:Caller caller, http:Request req, int appointmentNo) {
    // Get appoitment from appointments map using appointment number.
    var appointment = appointments[appointmentNo.toString()];

    if (appointment is Appointment) {
        // constructFrom appointment record to json.
        json|error appointmentJson = json.constructFrom(appointment);

        if (appointmentJson is json) {
            sendResponse(caller, appointmentJson);
        } else {
            log:printError("Error occurred when constructFroming appointment record to JSON.", err = appointmentJson);
            sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    } else {
        log:printInfo("User error in getAppointment, Invalid appointment number: " + appointmentNo.toString());
        sendResponse(caller, "Invalid appointment number.", statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Check channeling fee for a given appointment number.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need to check channeling fee
function checkChannellingFee(http:Caller caller, http:Request req, int appointmentNo) {
    io:println(appointments);
    // Check whether there is an appointment with the given appointment number.
    if (containsAppointmentId(appointments, appointmentNo.toString())) {
        Patient patient = <Patient> appointments[appointmentNo.toString()]["patient"];
        Doctor doctor = <Doctor> appointments[appointmentNo.toString()]["doctor"];

        // Create channeling fee record.
        ChannelingFee channelingFee = {
            patientName: <string>patient["name"],
            doctorName: <string>doctor["name"],
            actualFee: doctor["fee"].toString()
        };

        // constructFrom channeling fee record to json.
        json|error channelingFeeJson = json.constructFrom(channelingFee);
        if (channelingFeeJson is json) {
            sendResponse(caller, channelingFeeJson);
        } else {
            log:printError("Error occurred when constructFroming channelingFee record to JSON.", 
                err = channelingFeeJson);
            sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    } else {
        log:printInfo("User error in checkChannellingFee, Could not Find the Requested appointment ID: " 
            + appointmentNo.toString());
        sendResponse(caller, "Error. Could not Find the Requested appointment ID.", 
            statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Update patient record with symptoms and treatments.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
function updatePatientRecord(http:Caller caller, http:Request req, HospitalDAO hospitalDao) {
    json|error patientDetails = req.getJsonPayload();

    if (patientDetails is json) {
        string ssn = patientDetails.ssn.toString();
        // Validate symptoms and treatments in the request.
        if ((patientDetails.symptoms is json[]) && (patientDetails.treatments is json[])) {
            string[] symptoms = convertJsonToStringArray(<json[]>patientDetails.symptoms);
            string[] treatments = convertJsonToStringArray(<json[]>patientDetails.treatments);

            // Get the patient from patients map.
            var patient = hospitalDao["patientMap"][ssn];
            if (patient is Patient) {
                // Get the patient record from patient record map.
                var patientRecord = hospitalDao["patientRecordMap"][ssn];
                if (patientRecord is PatientRecord) {
                    // Update symptoms and treatments in the patient record.
                    if (updateSymptomsInPatientRecord(patientRecord, symptoms)
                                            && updateTreatmentsInPatientRecord(patientRecord, treatments)) {
                        sendResponse(caller, "Record Update Success.");
                    } else {
                        log:printError("Record Update Failed when updating patient record. "
                                                + "updateSymptomsInPatientRecord: "
                                                + updateSymptomsInPatientRecord(patientRecord, symptoms).toString()
                                                + "updateTreatmentsInPatientRecord: "
                                                + updateTreatmentsInPatientRecord(patientRecord, symptoms).toString());
                        sendResponse(caller, "Record Update Failed.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                    }
                } else {
                    log:printInfo("User error when updating patient record, Could not find valid Patient Record.");
                    sendResponse(caller, "Could not find valid Patient Record.", statusCode = http:STATUS_BAD_REQUEST);
                }
            } else {
                log:printInfo("User error when updating patient record, Could not find valid Patient Entry.");
                sendResponse(caller, "Could not find valid Patient Entry.", statusCode = http:STATUS_BAD_REQUEST);
            }
        } else {
            log:printInfo("User error when updating patient record, Invalid payload received.");
            sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        log:printInfo("User error when updating patient record, Invalid payload received.");
        sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Get patient record from the given ssn.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
# + ssn - Patient's ssn number
function getPatientRecord(http:Caller caller, http:Request req, HospitalDAO hospitalDao, string ssn) {
    var patientRecord = hospitalDao["patientRecordMap"][ssn];

    if (patientRecord is PatientRecord) {
        // constructFrom patient record in to json.
        json|error patientRecordJson = json.constructFrom(patientRecord);
        if (patientRecordJson is json) {
            sendResponse(caller, patientRecordJson);
        } else {
            log:printError("Error occurred when constructFroming channelingFee record to JSON.", 
                                                                                err = patientRecordJson);
            sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    } else {
        log:printInfo("User error in getPatientRecord, Could not find valid Patient Entry.");
        sendResponse(caller, "Could not find valid Patient Entry.", statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Check whether patient in the appoinment eligible for discounts.
#
# + caller - HTTP caller 
# + req - HTTP request
# + appointmentNo - Appointment number which need to check the eligibility for discounts.
function isEligibleForDiscount(http:Caller caller, http:Request req, int appointmentNo) {
    // Get the relevant appointment from the appointments map.
    var appointment = appointments[appointmentNo.toString()];

    if (appointment is Appointment) {
        boolean|error eligible = checkDiscountEligibility(<string>appointment["patient"]["dob"]);
        if (eligible is boolean) {
            sendResponse(caller, eligible);
        } else {
            log:printError("Error occurred when checking discount eligibility.", err = eligible);
            sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    } else {
        log:printInfo("User error in isEligibleForDiscount, Invalid appointment ID: " + appointmentNo.toString());
        sendResponse(caller, "Invalid appointment ID.", statusCode = http:STATUS_BAD_REQUEST);
    }
}

# Add new doctor to the hospital.
#
# + caller - HTTP caller 
# + req - HTTP request
# + hospitalDao - Hospital DAO record
function addNewDoctor(http:Caller caller, http:Request req, @tainted HospitalDAO hospitalDao) {
    var doctorDetails = req.getJsonPayload();

    if (doctorDetails is json) {
        // Create doctor record from request payload.
        Doctor|error doc = Doctor.constructFrom(doctorDetails);
        
        if(doc is Doctor) {
            string category = <string>doc["category"];
            // If new doctor's category is not exists in hospital categories add it to it.
            if (!(containsStringElement(<string[]>hospitalDao["categories"], category))) {
                string[] tempArr = <string[]>hospitalDao["categories"];
                tempArr[tempArr.length()] = category;
                hospitalDao["categories"] = tempArr;
            }

            // Check whether same doctor already added.
            Doctor|error doctor = findDoctorByName(<@untainted> hospitalDao, <string>doctorDetails.name);
            if (doctor is Doctor) {
                log:printInfo("User error in addNewDoctor, Doctor Already Exists in the system.");
                sendResponse(caller, "Doctor Already Exists in the system.", statusCode = http:STATUS_BAD_REQUEST);
            } else {
                // Add new doctor to the hospital.
                hospitalDao["doctorsList"][<int>hospitalDao["doctorsList"].length()] = doc;
                sendResponse(caller, "New Doctor Added Successfully.");
            }
        } else {
            log:printError("Could not constructFrom recieved payload to Doctor record.", err = doc);
            sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        log:printInfo("User error when adding a new doctor: Invalid payload received.");
        sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
    }
}
