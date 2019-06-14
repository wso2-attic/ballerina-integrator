import ballerina/http;
import ballerina/log;
import ballerina/io;

http:Client healthcareServiceEP = new("http://localhost:9090/healthcare");
http:Client hospitalServiceEP = new("http://localhost:9090/grandoaks/categories");

service analyticsService on new http:Listener(8080) {
    resource function analytics(http:Caller caller, http:Request request) {
        http:Response | error response = new;
        string appointmentNumber;
        string ssn;
        json | error jsonPayload = {};
        string | error textPayload = "";


        io:println("Analytics Profile : Calling all endpoints");

        //Calling Get Doctor endpoint with category surgery
        //Other possible categories include [cardiology, gynaecology, ent, paediatric]
        response = healthcareServiceEP->get("/surgery");
        if (response is http:Response) {
            io:println("Get Doctors Endpoint : Category 'Surgery'");
            jsonPayload = response.getJsonPayload();

            if (jsonPayload is json) {
                io:println("\n Available doctors " + jsonPayload.toString());
            } else {
                io:println("Error : Recieved invalid payload");        
            }
        }

        //Calling Reserve Appointment endpoint with category surgery
        json payload = {
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

        response = hospitalServiceEP->post("/surgery/reserve", payload);

        if (response is http:Response) {
            io:println("\nReservation Endpoint");
            io:println("Sending details : " + payload.toString());
            jsonPayload = response.getJsonPayload();
            
            if (jsonPayload is json) {
                io:println("Reservation made");
                appointmentNumber = jsonPayload.appointmentNumber.toString();
                ssn = jsonPayload.patient.ssn.toString();
                json reservationPayload = jsonPayload;
                
                //Calling Get Appointment endpoint with appointmentId
                response = healthcareServiceEP->get("/appointments/" + untaint appointmentNumber);

                if (response is http:Response) {
                    io:println("Get Appointment Endpoint");

                    jsonPayload = response.getJsonPayload();

                    if (jsonPayload is json) {
                        io:println("Reserved Appointment : " + jsonPayload.toString());
                    } else {
                        io:println("\n Error : Recieved invalid payload");                    
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Appointment validation endpoint with appointmentId
                response = healthcareServiceEP->get("/appointments/validity/" + untaint appointmentNumber);

                if(response is http:Response) {
                    io:println("\nAppointment Validation Endpoint");
                    
                    jsonPayload = response.getJsonPayload();

                    if(jsonPayload is json) {
                        io:println("Appointment time validity: " +  jsonPayload.toString());
                    } else {
                        io:println("\n Error : Recieved invalid payload");
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Channeling fee endpoint with appointmentId
                response = hospitalServiceEP->get("/appointments/" + untaint appointmentNumber + "/fee");

                if(response is http:Response) {
                    io:println("\nChanneling Fee Endpoint");

                    jsonPayload = response.getJsonPayload();

                    if(jsonPayload is json) {
                        io:println("Channeling fee : " + jsonPayload.toString());
                    } else {
                        io:println("\n Error : Recieved invalid payload");
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Get patient record
                response = hospitalServiceEP->get("/patient/" + untaint ssn + "/getrecord");

                if(response is http:Response) {
                    io:println("\nGet Patient Record Endpoint");

                    jsonPayload = response.getJsonPayload();

                    if(jsonPayload is json) {
                        io:println("Patient Record : " + jsonPayload.toString());
                    } else {
                        io:println("\n Error : Recieved invalid payload");
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Update patient record
                json updatePatient = {
	                "symptoms":["Cough"],
	                "treatments":["Panadol"],
                    "ssn":"234-23-525" 
                };
                response = hospitalServiceEP->post("/patient/updaterecord",updatePatient);

                if(response is http:Response) {
                    io:println("\nUpdate Patient Record Endpoint");

                    textPayload = response.getTextPayload();
                    
                    if(textPayload is string) {
                        io:println(textPayload);
                    } else {
                        io:println("\nError : Recieved invalid payload");
                    } 
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Is eligible for discount 
                response = hospitalServiceEP->get("/patient/appointment/" + untaint appointmentNumber + "/discount");

                if(response is http:Response) {
                    io:println("\nIs Eligible for Discount Endpoint");

                    textPayload = response.getTextPayload();

                    if(textPayload is string) {
                        io:println(textPayload);
                    } else {
                        io:println("\nError : Recieved invalid payload");
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //Settle payment
                response = healthcareServiceEP->post("/payments", untaint reservationPayload);

                if(response is http:Response) {
                    io:println("\n Settle Payment Endpoint");

                    textPayload = response.getTextPayload();

                    if(textPayload is string) {
                        io:println(textPayload);
                    } else {
                        io:println("\nError : Recieved invalid payload");
                    }
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                //TODO : Settle payment details

                //Add new Doctor
                json newDoctorPayload = {
                    name: "susan clement",
                    hospital: "grand oak community hospital",
                    category: "surgery",
                    availability: "9.00 a.m - 12.00 a.m",
                    fee: 12000.00
                };

                response = healthcareServiceEP->post("/admin/newdoctor", untaint newDoctorPayload);

                if(response is http:Response) {
                    io:println("\n Add New Doctor Endpoint");

                    textPayload = response.getTextPayload();

                    if(textPayload is string) {
                        io:println(textPayload);
                        response.setPayload("Analytics Service Successfully executed");
                    } else {
                        io:println("\nError : Recieved invalid payload");
                    }

                    respondWithSuccess(caller);
                } else {
                    respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
                }

                
            } else {
                io:println("\n Error : Recieved invalid payload");            //TODO Change to error
            }

            
        } else {
            respondWithError(caller, <string>response.detail().message, "Invalid response recieved");
        }
    }
}

function respondWithSuccess(http:Caller caller) {
    http:Response response = new;
    response.statusCode = 200;
    response.setPayload("Analytics Service successfully called Healthcare Service Endpoints. Please verify Grafana for metrics");
}
#Respond in error cases
function respondWithError(http:Caller caller, string payload, string failedMessage) {
    http:Response response = new;
    response.statusCode = 500;
    response.setPayload(payload);
    
    var result = caller->respond(response);
    if(result is error) {
        log:printError("Error responding to caller", err = result);
    }
    
}

