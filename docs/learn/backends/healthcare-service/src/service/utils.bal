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
import ballerina/system;
import ballerina/time;
import ballerina/log;
import ballerinax/java;
import ballerina/'lang\.int as ints;

// Initialize appoint number as 1.
int appointmentNo = 1;
// Conversion error.
type CannotConvertError error<string>;

# Send HTTP response.
#
# + caller - HTTP caller 
# + payload - payload or the response
# + statusCode - status code of the response
public function sendResponse(http:Caller caller, json|string payload, int statusCode = 200) {
    http:Response response = new;
    response.setPayload(<@untainted> payload);
    response.statusCode = statusCode;
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error sending response.", err = result);
    }
}

# Check whether given string contains in the given array.
#
# + arr - array 
# + element - string want to check
# + return - given string is contains in the array
public function containsStringElement(string[] arr, string element) returns boolean {
    foreach var item in arr {
        if (equalsIgnoreCase(item, element)) {
            return true;
        }
    }
    return false;
}

# Check given ssn contains in the given patient record map.
#
# + patientRecordMap - patientRecord map 
# + ssn - ssn want to check
# + return - given ssn is contains in the patientRecord map
public function containsInPatientRecordMap(map<PatientRecord> patientRecordMap, string ssn) returns boolean {
    foreach PatientRecord pRecord in patientRecordMap {
        Patient patient = <Patient> pRecord["patient"];
        if (equalsIgnoreCase(patient["ssn"], ssn)) {
            return true;
        }    
    }
    return false;
}

# Convert JSON array to string array.
#
# + array - JSON array want to convert 
# + return - converted string array
public function convertJsonToStringArray(json[] array) returns string[] {
    string[] result = [];
    foreach var item in array {
        result[result.length()] = <string>item;
    }
    return result;
}

# Create new payment entry.
#
# + paymentSettlement - paymentSettlement record
# + healthcareDao - healthcareDAO record
# + return - Payment record created | error
public function createNewPaymentEntry(PaymentSettlement paymentSettlement, HealthcareDao healthcareDao) 
                                            returns Payment|error {
    int|error discount = checkForDiscounts(<string>paymentSettlement["patient"]["dob"]);
    if(discount is int) {
        string doctorName = <string>paymentSettlement["doctor"]["name"];
        Doctor|error doctor = findDoctorByNameFromHelathcareDao(healthcareDao, doctorName);
        if(doctor is Doctor){
            float discounted = (<float>doctor["fee"] / 100) * (100 - discount);

            Payment payment = {
                appointmentNo: <int>paymentSettlement["appointmentNumber"],
                doctorName: <string>paymentSettlement["doctor"]["name"],
                patient: <string>paymentSettlement["patient"]["name"],
                actualFee: <float>doctor["fee"],
                discount: discount: 0,
                discounted: discounted: 0.0,
                paymentID: system:uuid(),
                status: ""
            };
            return payment;
        } else {
            return doctor;
        }
    } else {
        return discount;
    }
}

# Make new appointment.
#
# + appointmentRequest - appointmentRequest record
# + hospitalDao - hospitalDAO record
# + return - appointment created | doctor not found error
public function makeNewAppointment(AppointmentRequest appointmentRequest, HospitalDAO hospitalDao) 
                                            returns Appointment | DoctorNotFoundError {
    var doc = findDoctorByName(hospitalDao, appointmentRequest.doctor);
    if (doc is DoctorNotFoundError) {
        return doc;
    } else {
        Appointment appointment = {
            appointmentNumber: appointmentNo,
            doctor: doc,
            patient: appointmentRequest.patient,
            fee: doc.fee,
            confirmed: false,
            appointmentDate: appointmentRequest.appointmentDate
        };
        appointmentNo = appointmentNo + 1;
        return appointment;
    }
}

# Discount is calculated by checking birth year of the patient.
#
# + dob - date of birth as a string in yyyy-MM-dd format 
# + return - discount value
public function checkForDiscounts(string dob) returns int|error {
    handle result = split(java:fromString(dob), java:fromString("-"));
    string? yobStr = java:toString(java:getArrayElement(result, 0));

    if (yobStr is string) {
        int|error yob = ints:fromString(yobStr);
        if(yob is int) {
            int currentYear = time:getYear(time:currentTime());
            int age = currentYear - yob;
            if (age < 12) {
                return 15;
            } else if (age > 55) {
                return 20;
            } else {
                return 0;
            }
        } else {
            CannotConvertError err = error("Invalid Date of birth:" + dob);
            return err;
        }
    } else {
        CannotConvertError err = error("Invalid Date of birth: yobStr is ().");
        return err;  
    }
}

# Check discount eligibility by checking the birth year of the patient.
#
# + dob - date of birth as a string in yyyy-MM-dd format 
# + return - eligibity for discounts | error
public function checkDiscountEligibility(string dob) returns boolean | error {
    handle result = split(java:fromString(dob), java:fromString("-"));
    string? dobStr = java:toString(java:getArrayElement(result, 0));

    if (dobStr is string) {
    int|error yob = ints:fromString(dobStr);
        if (yob is int) {
            int currentYear = time:getYear(time:currentTime());
            int age = currentYear - yob;

            if (age < 12 || age > 55) {
                return true;
            } else {
                return false;
            }
        } else {
            log:printError("Error occurred when converting string dob year to int.", err = ());
            return yob;
        }
    } else {
        CannotConvertError err = error("Invalid Date of birth: dobStr is ().");
        return err; 
    }
}

# Check whether given appointment is containts in the appointments map.
#
# + appointmentsMap - appointments map of the hospital
# + id - appointment id 
# + return - appointment contains in the appointments map
public function containsAppointmentId(map<Appointment> appointmentsMap, string id) returns boolean {
    foreach Appointment appointment in appointmentsMap {
        if (equalsIgnoreCase(appointment["appointmentNumber"].toString(), id)) {
            return true;
        }
    }
    return false;
}

# Convert string to boolean
# + value - string value
# + return - converted boolean
function getBooleanValue(string value) returns boolean {
    if (value == "true") {
        return true;
    } else if (value == "false") {
        return false;
    } else {
        log:printError("Invalid boolean value, string value='" + value + "' ", err = ());
        return false;
    }
}

# Check whether given two strings are equal without considering the case.
# + str1 - first string
# + str2 - second string
# + return - is two strings equal without considering the case
function equalsIgnoreCase(string str1, string str2) returns boolean {
    if (str1.toUpperAscii() == str2.toUpperAscii()) {
        return true;
    } else {
        return false;
    }
}
