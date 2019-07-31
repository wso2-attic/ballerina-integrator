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

import daos;
import ballerina/http;
import ballerina/system;
import ballerina/time;
import ballerina/log;

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
    response.setPayload(untaint payload);
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
        if (item.equalsIgnoreCase(element)) {
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
public function containsInPatientRecordMap(map<daos:PatientRecord> patientRecordMap, string ssn) returns boolean {
    foreach (string, daos:PatientRecord) (k, v) in patientRecordMap {
        daos:Patient patient = <daos:Patient> v["patient"];
        if (<boolean>patient["ssn"].equalsIgnoreCase(ssn)) {
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
public function createNewPaymentEntry(daos:PaymentSettlement paymentSettlement, daos:HealthcareDao healthcareDao) 
                                            returns daos:Payment|error {
    int|error discount = checkForDiscounts(<string>paymentSettlement["patient"]["dob"]);
    if(discount is int) {
        string doctorName = <string>paymentSettlement["doctor"]["name"];
        daos:Doctor|error doctor = daos:findDoctorByNameFromHelathcareDao(healthcareDao, doctorName);
        if(doctor is daos:Doctor){
            float discounted = (<float>doctor["fee"] / 100) * (100 - discount);

            daos:Payment payment = {
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
public function makeNewAppointment(daos:AppointmentRequest appointmentRequest, daos:HospitalDAO hospitalDao) 
                                            returns daos:Appointment | daos:DoctorNotFoundError {
    var doc = daos:findDoctorByName(hospitalDao, appointmentRequest.doctor);
    if (doc is daos:DoctorNotFoundError) {
        return doc;
    } else {
        daos:Appointment appointment = {
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
    int|error yob = int.convert(dob.split("-")[0]);
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
}

# Check discount eligibility by checking the birth year of the patient.
#
# + dob - date of birth as a string in yyyy-MM-dd format 
# + return - eligibity for discounts | error
public function checkDiscountEligibility(string dob) returns boolean | error {
    var yob = int.convert(dob.split("-")[0]);
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
}

# Check whether given appointment is containts in the appointments map.
#
# + appointmentsMap - appointments map of the hospital
# + id - appointment id 
# + return - appointment contains in the appointments map
public function containsAppointmentId(map<daos:Appointment> appointmentsMap, string id) returns boolean {
    foreach (string, daos:Appointment) (k, v) in appointmentsMap {
        if (k.equalsIgnoreCase(id)) {
            return true;
        }
    }
    return false;
}
