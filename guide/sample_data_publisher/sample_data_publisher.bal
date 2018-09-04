import ballerina/io;
import ballerina/config;
import ballerina/http;
import ballerina/log;

// Client endpoint to communicate with appointment management service
endpoint http:Client appointmentEP {
    url: "http://localhost:9092/appointment-mgt"
    //url: "http://ballerina.guides.io/appointment-mgt"
};

// Client endpoint to communicate with medical record service
endpoint http:Client medicalRecordEP {
    url: "http://localhost:9093/medical-records"
    //url: "http://ballerina.guides.io/medical-records"
};

// Client endpoint to communicate with notification management service
endpoint http:Client notificationEP {
    url: "http://localhost:9094/notification-mgt"
    //url: "http://ballerina.guides.io/notification-mgt"
};

// Client endpoint to communicate with message management service
endpoint http:Client messageEP {
    url: "http://localhost:9095/message-mgt"
    //url: "http://ballerina.guides.io/message-mgt"
};


function main(string... args) {

    io:println("Publishing sample data to services...");

    json response;

    //TODO: Read sample data from a config file
    io:println("Adding Appointments...");
    json appointmentData1 = { "Appointment": { "ID": "APT01", "Name": "Family Medicine", "Location": "Main Hospital", "Time":"2018-08-23, 08.30AM", "Description": "Doctor visit for family medicine"}};
    json appointmentData2 = { "Appointment": { "ID": "APT02", "Name": "Lab Test Appointment", "Location": "Main Lab", "Time":"2018-08-20, 07.30AM", "Description": "Blood test"}};
    response = sendPostRequest(appointmentEP, "/appointment", appointmentData1);
    response = sendPostRequest(appointmentEP, "/appointment", appointmentData2);

    io:println("Adding Medical Records...");
    json medicalRecordData1 = { "MedicalRecord": { "ID": "MED01", "Name": "Fasting Glucose Test", "Description": "Test Result for Fasting Glucose test is normal"}};
    json medicalRecordData2 = { "MedicalRecord": { "ID": "MED02", "Name": "Allergies", "Description": "Allergy condition recorded due to Summer allergies"}};
    response = sendPostRequest(medicalRecordEP, "/medical-record", medicalRecordData1);
    response = sendPostRequest(medicalRecordEP, "/medical-record", medicalRecordData2);

    io: println("Adding Notification...");
    json notificationData1 = { "Notification": { "ID": "NOT01", "Name": "Lab Test Result Notification", "Description": "Test Result of Glucose test is ready"}};
    json notificationData2 = { "Notification": { "ID": "NOT02", "Name": "Flu Vaccine Status", "Description": "Flu vaccines due for this year"}};
    response = sendPostRequest(notificationEP, "/notification", notificationData1);
    response = sendPostRequest(notificationEP, "/notification", notificationData2);


    io:println("Adding Messages...");
    json messageData1 = { "Message": { "ID": "MSG01", "From":"Dr. Caroline Caroline", "Subject": "Regarding Glucose test result", "Content": "Dear member, your test result remain normal", "Status" : "Read"}};
    json messageData2 = { "Message": { "ID": "MSG02", "From":"Dr. Sandra Robert", "Subject": "Regarding flu season", "Content": "Dear member, We highly recommend you to get the flu vaccination to prevent yourself from flu", "Status" : "Unread"}};
    json messageData3 = { "Message": { "ID": "MSG03", "From":"Dr. Peter Mayr", "Subject": "Regarding upcoming blood test", "Content": "Dear member, Your Glucose test is scheduled in early next month", "Status" : "Unread"}};
    response = sendPostRequest(messageEP, "/message", messageData1);
    response = sendPostRequest(messageEP, "/message", messageData2);
    response = sendPostRequest(messageEP, "/message", messageData3);


    io:println("Data publishing completed");

}

// Function which takes http client endpoint, context and data as a input
//This will perform a HTTP POST against given endpoint and return a json response
function sendPostRequest(http:Client client , string context, json data) returns (json) {

    endpoint http:Client client1 = client;

    http:Request req = new;
    req.setJsonPayload(data);

    var response = client1->post(context, req);

    json value;


    match response {
        http:Response resp => {
            var msg = resp.getJsonPayload();
            match msg {
                json jsonPayload => {
                    value = jsonPayload;
                }
                error err => {
                    log:printError(err.message, err = err);
                }
            }
        }
        error err => {
            log:printError(err.message, err = err);
        }
    }
    return value ;
}



// Function which takes http client endpoint and context as a input
// This will call given endpoint and return a json response
function sendGetRequest(http:Client httpClient1, string context) returns (json) {

    endpoint http:Client client1 = httpClient1;
    var response = client1->get(context);
    json value;

    match response {
        http:Response resp => {
            var msg = resp.getJsonPayload();
            match msg {
                json jsonPayload => {
                    io:println(jsonPayload);
                    value = jsonPayload;
                }
                error err => {
                    log:printError(err.message, err = err);
                }
            }
        }
        error err => {
            log:printError(err.message, err = err);
        }
    }
    return value;
}


