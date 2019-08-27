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

import ballerina/log;
import ballerina/time;

# Hospital DAO record.
#
# + doctorsList - list of doctors in the hospital 
# + categories - doctor categories 
# + patientMap - map of details of patients 
# + patientRecordMap - map of patients records in the hospital
public type HospitalDAO record {
    Doctor[] doctorsList = [];
    string[] categories = [];
    map<Patient> patientMap = {};
    map<PatientRecord> patientRecordMap = {};
};

# Appointment request record.
#
# + patient - patient of the appointment 
# + doctor - doctor of the appointment  
# + hospital - hospital of the appointment  
# + appointmentDate - appointment date
public type AppointmentRequest record {
    Patient patient;
    string doctor;
    string hospital;
    string appointmentDate;
};

# Appointment record.
#
# + time - time of the appointment 
# + appointmentNumber - appointment number 
# + doctor - doctor of the appointment 
# + patient - patient of the appointment 
# + hospital - hospital of the appointment 
# + fee - fee for the appointment  
# + confirmed - appointment is confirmed or not 
# + paymentID - payment id of the appointment  
# + appointmentDate - appointment date
public type Appointment record {
    string time?;
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital?;
    float fee;
    boolean confirmed;
    string paymentID?;
    string appointmentDate?;
};

# Doctor record.
#
# + name - doctor name 
# + hospital - hospital which doctor works
# + category - specialized category of the doctor
# + availability - availability in a working day
# + fee - doctor charge
public type Doctor record {
    string name;
    string hospital;
    string category;
    string availability;
    float fee;
};

# Patient record.
#
# + name - patient name 
# + dob - date of birth of the patient
# + ssn - ssn number of the patient
# + address - address of the patient
# + phone - phone number of the patient
# + email - email of the patient
public type Patient record {
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
};

# Patient record which maintains by the hospital.
#
# + patient - patient  
# + symptoms - symptoms of the patient 
# + treatments - treatments provided to the patient by the hospital
public type PatientRecord record {
    Patient patient;
    map<string[]> symptoms = {};
    map<string[]> treatments = {};
};

# Update treatments in the patient record.
#
# + patientRecord - patientRecord record
# + treatments - treatments provided to the patient
# + return - patientRecord is successfuly updated or not
public function updateTreatmentsInPatientRecord(PatientRecord patientRecord, string[] treatments) returns boolean {
    time:Time currentTime = time:currentTime();
    var date = time:format(currentTime, "dd-MM-yyyy");
    if date is error {
        log:printError("Error getting the current date.");
        return false;
    } else {
        patientRecord.treatments[date] = treatments;
        return true;
    }
}

# Update symptoms in the patient record.
#
# + patientRecord - patientRecord record
# + symptoms - symptoms of the patient
# + return - patientRecord is successfuly updated or not
public function updateSymptomsInPatientRecord(PatientRecord patientRecord, string[] symptoms) returns boolean {
    time:Time currentTime = time:currentTime();
    var date = time:format(currentTime, "dd-MM-yyyy");
    if date is error {
        log:printError("Error getting the current date.");
        return false;
    } else {
        patientRecord.symptoms[date] = symptoms;
        return true;
    }
}

# Find doctors from the given category in the hospital DAO.
#
# + hospitalDao - hospitalDAO record
# + category - doctor category 
# + return - list of doctors
public function findDoctorByCategory(HospitalDAO hospitalDao, string category) returns Doctor[] {
    Doctor[] list = [];
    foreach Doctor doctor in hospitalDao.doctorsList {
        if (equalsIgnoreCase(category, doctor.category)) {
            list[list.length()] = doctor;
        }
    }
    return list;
}

# Find doctor by given name in hospital DAO.
#
# + hospitalDao - hospitalDAO record
# + name - doctor name 
# + return - doctor name matching to the given name | doctor not found error
public function findDoctorByName(HospitalDAO hospitalDao, string name) returns Doctor | DoctorNotFoundError {
    foreach var doctor in hospitalDao.doctorsList {
        if (equalsIgnoreCase(name, doctor.name)) {
            return doctor;
        }
    }
    string errorReason = "Doctor Not Found: " + name;
    DoctorNotFoundError notFoundError = error(errorReason);
    return notFoundError;
}
