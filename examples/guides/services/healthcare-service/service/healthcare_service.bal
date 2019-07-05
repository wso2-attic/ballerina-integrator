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
import ballerina/io;
import ballerina/log;
import ballerina/time;
import daos;
import util;

listener http:Listener httpListener = new(9095);

// Healthcare REST service.
@http:ServiceConfig {
    basePath: "/healthcare"
}
service HealthcareService on httpListener {

    // Create hospital services.
    ClemencyHospitalService clemency = new;
    GrandOakHospitalService grandoaks = new;
    PineValleyHospitalService pinevalley = new;
    WillowGardensHospitalService willowgarden = new;

    // Create health care DAO record.
    daos:HealthcareDao healthcareDao = {
        doctorsList: [
            clemency.doctor1, 
            clemency.doctor2, 
            clemency.doctor3,
            grandoaks.doctor1, 
            grandoaks.doctor2, 
            grandoaks.doctor3,
            grandoaks.doctor4, 
            pinevalley.doctor1, 
            pinevalley.doctor2,
            willowgarden.doctor1, 
            willowgarden.doctor2
        ],
        categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
        payments: {}
    };

    // Initialize appointments map.
    map<daos:Appointment> appointments = {};

    // Get doctors for a given category.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/queryDoctor/{category}"
    }
    resource function getDoctors(http:Caller caller, http:Request req, string category) {
        // Get doctors for a given category from healthcare DAO.
        daos:Doctor[] stock = daos:findDoctorByCategoryFromHealthcareDao(self.healthcareDao, category);

        if(stock.length() > 0) {
            // Convert doctors record array to json.
            json|error payload = json.convert(stock);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                                statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            util:sendResponse(caller, "Could not find any entry for the requested Category.");
        }
    }

    // Get appointment for given appointment number.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        // Get appointment from appointments map.
        daos:Appointment? appointment = self.appointments[string.convert(appointmentId)];

        if (appointment is daos:Appointment) {
            json|error payload = json.convert(appointment);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                                statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getAppointment, There is no appointment with appointment number " 
                                                                                        + appointmentId);
            util:sendResponse(caller, "Error. There is no appointment with appointment number " + appointmentId, 
                                                                                        statusCode = 400);
        }
    }

    // Check validity of an appointment.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/validity/{appointmentId}"
    }
    resource function getAppointmentValidityTime(http:Caller caller, http:Request req, string appointmentId) {
        // Get appointment from appointments map.
        daos:Appointment? appointment = self.appointments[appointmentId];
        int diffDays = 0;

        if (appointment is daos:Appointment) {
            var date = time:parse(<string>appointment["appointmentDate"], "yyyy-MM-dd");
            if (date is time:Time) {
                time:Time today = time:currentTime();
                // Get no of days remaining for the appointment.
                diffDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
                util:sendResponse(caller, diffDays);
            } else {
                log:printError("Invalid date in the appointent with ID: " + appointmentId, err = date);
                util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getAppointment: There is no appointment with appointment number " 
                                                                                            + appointmentId);
            util:sendResponse(caller, "Error.Could not Find the Requested appointment ID", statusCode = 400);
        }
    }

    // Delete an appointment.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/appointments/{appointmentId}"
    }
    resource function removeAppointment(http:Caller caller, http:Request req, string appointmentId) {
        if(self.appointments.remove(appointmentId)) {
            util:sendResponse(caller, "Appointment is successfully removed.");
        } else {
            log:printInfo("Failed to remove appoitment with appointment number " + appointmentId);
            util:sendResponse(caller, "Failed to remove appoitment with appointment number " + appointmentId, 
                                                                                        statusCode = 400);
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
            daos:PaymentSettlement|error paymentSettlement = 
                                                daos:PaymentSettlement.convert(paymentSettlementDetails);

            if(paymentSettlement is daos:PaymentSettlement) {
                string appointmentNo = string.convert(paymentSettlement.appointmentNumber);
                if(util:containsAppointmentId(self.appointments, appointmentNo)) {
                    // Create new payment entry for the appointment.
                    daos:Payment|error payment = 
                            util:createNewPaymentEntry(paymentSettlement, untaint self.healthcareDao);

                    if(payment is daos:Payment) {
                        // Make payment status `Settled`.
                        payment["status"] = "Settled";
                        self.healthcareDao["payments"][<string>payment["paymentID"]] = payment;
                        json payload = {
                            status: "success",
                            paymentId: <string>payment["paymentID"]
                        };
                        // Make appointment confirmed `true`.
                        self.appointments[appointmentNo].confirmed = true;
                        util:sendResponse(caller, payload);
                    } else {
                        log:printError("User error Invalid payload recieved, payload: ", err = payment);
                        util:sendResponse(caller, "Invalid payload recieved, " + payment.reason(), 
                                                                                        statusCode = 400);
                    }
                } else {
                    log:printError("Could not Find the Requested appointment ID: " + appointmentNo);
                    util:sendResponse(caller, "Error. Could not Find the Requested appointment ID.", 
                                                                                        statusCode = 400);
                }
            } else {
                log:printError("Could not convert recieved payload to PaymentSettlement.", 
                                                                                err = paymentSettlement);
                util:sendResponse(caller, "Invalid payload received", statusCode = 400);
            }
        } else {
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    }

    // Get the payment details for a given payment id.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/payments/payment/{paymentId}"
    }
    resource function getPaymentDetails(http:Caller caller, http:Request req, string paymentId) {
        // Get the payment record from healthcare DAO payments map. 
        var payment = self.healthcareDao["payments"][paymentId];

        if (payment is daos:Payment) {
            json|error payload = json.convert(payment);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred getPaymentDetails when converting Payment to JSON.", err = payload);
                util:sendResponse(caller, "Intrenal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getPaymentDetails, Invalid payment id provided: " + paymentId);
            util:sendResponse(caller, "Invalid payment id provided", statusCode = 400);
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
            daos:Doctor|error doc = daos:Doctor.convert(doctorDetails);

            if(doc is daos:Doctor) {
                string category = <string>doc["category"];
                // If new doctor's category is not exists in hospital categories add it to it.
                if (!util:containsStringElement(<string[]>self.healthcareDao["categories"], category)) {
                    string[] a = <string[]>self.healthcareDao["categories"];
                    a[a.length()] = category;
                    self.healthcareDao["categories"] = a;
                }

                // Check whether same doctor already added.
                var doctor = daos:findDoctorByNameFromHelathcareDao(untaint self.healthcareDao, 
                                                                                <string>doc["name"]);
                if (doctor is daos:Doctor) {
                    log:printInfo("User error in addNewDoctor, Doctor Already Exists in the system.");
                    util:sendResponse(caller, "Doctor Already Exist in the system", statusCode = 400);
                } else {
                    // Add new doctor to the hospital.
                    self.healthcareDao["doctorsList"][<int>self.healthcareDao["doctorsList"].length()] = doc;
                    util:sendResponse(caller, "New Doctor Added Successfully.");
                }
            } else {
                log:printError("Could not convert recieved payload to Doctor record.", err = doc);
                util:sendResponse(caller, "Invalid payload received", statusCode = 400);
            }
        } else {
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    }
}
