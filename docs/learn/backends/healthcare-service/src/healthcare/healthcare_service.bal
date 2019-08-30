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
import ballerina/time;

listener http:Listener httpListener = new(9095);

// Create health care DAO record.
HealthcareDao healthcareDao = {
    doctorsList: [
        doctorClemency1, 
        doctorClemency2, 
        doctorClemency3,
        doctorGrandOak1, 
        doctorGrandOak2, 
        doctorGrandOak3,
        doctorGrandOak4, 
        doctorPineValley1, 
        doctorPineValley2,
        doctorWillowGrdn1, 
        doctorWillowGrdn2
    ],
    categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
    payments: {}
};

// Initialize appointments map.
map<Appointment> appointments = {};

// Healthcare REST service.
@http:ServiceConfig {
    basePath: "/healthcare"
}
service HealthcareService on httpListener {
    // Get doctors for a given category.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/queryDoctor/{category}"
    }
    resource function getDoctors(http:Caller caller, http:Request req, string category) {
        // Get doctors for a given category from healthcare DAO.
        Doctor[] stock = findDoctorByCategoryFromHealthcareDao(healthcareDao, category);

        if(stock.length() > 0) {
            // Convert doctors record array to json.
            json|error payload = json.constructFrom(stock);
            if (payload is json) {
                sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        } else {
            sendResponse(caller, "Could not find any entry for the requested Category.");
        }
    }

    // Get appointment for given appointment number.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        // Get appointment from appointments map.
        Appointment? appointment = appointments[appointmentId.toString()];

        if (appointment is Appointment) {
            json|error payload = json.constructFrom(appointment);
            if (payload is json) {
                sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        } else {
            log:printInfo("User error in getAppointment, There is no appointment with appointment number " 
                + appointmentId.toString());
            sendResponse(caller, "Error. There is no appointment with appointment number " + appointmentId.toString(), 
                statusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Check validity of an appointment.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/validity/{appointmentId}"
    }
    resource function getAppointmentValidityTime(http:Caller caller, http:Request req, string appointmentId) {
        // Get appointment from appointments map.
        Appointment? appointment = appointments[appointmentId];
        int diffDays = 0;

        if (appointment is Appointment) {
            var date = time:parse(<string>appointment["appointmentDate"], "yyyy-MM-dd");
            if (date is time:Time) {
                time:Time today = time:currentTime();
                // Get no of days remaining for the appointment.
                diffDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
                sendResponse(caller, diffDays);
            } else {
                log:printError("Invalid date in the appointent with ID: " + appointmentId, err = date);
                sendResponse(caller, "Internal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        } else {
            log:printInfo("User error in getAppointment: There is no appointment with appointment number " 
                                                                                            + appointmentId);
            sendResponse(caller, "Error.Could not Find the Requested appointment ID", statusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Delete an appointment.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/appointments/{appointmentId}"
    }
    resource function removeAppointment(http:Caller caller, http:Request req, string appointmentId) {
        if(appointments.hasKey(appointmentId)) {
            Appointment app = appointments.remove(appointmentId);
            sendResponse(caller, "Appointment is successfully removed.");
        } else {
            sendResponse(caller, "Invalid appointment number " + appointmentId, statusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Settle payment for an appointment.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/payments"
    }
    resource function settlePayment(http:Caller caller, http:Request req) {
        var paymentSettlementDetails = req.getJsonPayload();

        if (paymentSettlementDetails is json) {
            PaymentSettlement|error paymentSettlement = 
                PaymentSettlement.constructFrom(paymentSettlementDetails);

            if(paymentSettlement is PaymentSettlement) {
                string appointmentNo = paymentSettlement.appointmentNumber.toString();
                if(containsAppointmentId(appointments, appointmentNo)) {
                    // Create new payment entry for the appointment.
                    Payment|error payment = 
                            createNewPaymentEntry(paymentSettlement, <@untainted> healthcareDao);

                    if(payment is Payment) {
                        // Make payment status `Settled`.
                        payment["status"] = "Settled";
                        healthcareDao["payments"][<string>payment["paymentID"]] = payment;
                        json payload = {
                            status: "success",
                            paymentId: <string>payment["paymentID"]
                        };
                        // Make appointment confirmed `true`.
                        appointments[appointmentNo].confirmed = true;
                        sendResponse(caller, payload);
                    } else {
                        log:printError("User error Invalid payload recieved, payload: ", err = payment);
                        sendResponse(caller, "Invalid payload recieved, " + payment.reason(), 
                            statusCode = http:STATUS_BAD_REQUEST);
                    }
                } else {
                    log:printError("Could not Find the Requested appointment ID: " + appointmentNo);
                    sendResponse(caller, "Could not Find the Requested appointment ID.", 
                        statusCode = http:STATUS_BAD_REQUEST);
                }
            } else {
                log:printError("Could not convert recieved payload to PaymentSettlement.", err = paymentSettlement);
                sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
            }
        } else {
            sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Get the payment details for a given payment id.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/payments/payment/{paymentId}"
    }
    resource function getPaymentDetails(http:Caller caller, http:Request req, string paymentId) {
        // Get the payment record from healthcare DAO payments map. 
        var payment = healthcareDao["payments"][paymentId];

        if (payment is Payment) {
            json|error payload = json.constructFrom(payment);
            if (payload is json) {
                sendResponse(caller, payload);
            } else {
                log:printError("Error occurred getPaymentDetails when converting Payment to JSON.", err = payload);
                sendResponse(caller, "Intrenal error occurred.", statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        } else {
            log:printInfo("User error in getPaymentDetails, Invalid payment id provided: " + paymentId);
            sendResponse(caller, "Invalid payment id provided", statusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Add new doctor to the healthcare DAO.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) {
        var doctorDetails = req.getJsonPayload();

        if (doctorDetails is json) {
            // Create doctor record from request payload.
            Doctor|error doc = Doctor.constructFrom(doctorDetails);

            if(doc is Doctor) {
                string category = <string>doc["category"];
                // If new doctor's category is not exists in hospital categories add it to it.
                if (!containsStringElement(<string[]>healthcareDao["categories"], category)) {
                    string[] a = <string[]>healthcareDao["categories"];
                    a[a.length()] = category;
                    healthcareDao["categories"] = a;
                }

                // Check whether same doctor already added.
                var doctor = findDoctorByNameFromHelathcareDao(<@untainted> healthcareDao, 
                                                                                <string>doc["name"]);
                if (doctor is Doctor) {
                    log:printInfo("User error in addNewDoctor, Doctor Already Exists in the system.");
                    sendResponse(caller, "Doctor Already Exist in the system", statusCode = http:STATUS_BAD_REQUEST);
                } else {
                    // Add new doctor to the hospital.
                    healthcareDao["doctorsList"][<int>healthcareDao["doctorsList"].length()] = doc;
                    sendResponse(caller, "New Doctor Added Successfully.");
                }
            } else {
                log:printError("Could not convert recieved payload to Doctor record.", err = doc);
                sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
            }
        } else {
            sendResponse(caller, "Invalid payload received", statusCode = http:STATUS_BAD_REQUEST);
        }
    }
}
