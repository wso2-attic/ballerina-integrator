import ballerina/io;
import ballerina/config;
import ballerina/http;
import ballerina/log;

// Client endpoint to communicate with appointment management service
http:Client appointmentEP = new("http://localhost:9092/appointment-mgt");

// Client endpoint to communicate with medical record service
http:Client medicalRecordEP = new("http://localhost:9093/medical-records");

// Client endpoint to communicate with notification management service
http:Client notificationEP = new("http://localhost:9094/notification-mgt");

// Client endpoint to communicate with message management service
http:Client messageEP = new("http://localhost:9095/message-mgt");

public function main(string... args) {

    log:printInfo("Publishing sample data to services...");

    json response;

    //TODO: Read sample data from a config file
    log:printInfo("Adding Appointments...");
    json appointmentData1 = { "Appointment": { "ID": "APT01", "Name": "Family Medicine", "Location": "Main Hospital",
        "Time": "2018-08-23, 08.30AM", "Description": "Doctor visit for family medicine" } };
    json appointmentData2 = { "Appointment": { "ID": "APT02", "Name": "Lab Test Appointment", "Location": "Main Lab",
        "Time": "2018-08-20, 07.30AM", "Description": "Blood test" } };
    response = sendPostRequest(appointmentEP, "/appointment", appointmentData1);
    response = sendPostRequest(appointmentEP, "/appointment", appointmentData2);

    log:printInfo("Adding Medical Records...");
    json medicalRecordData1 = { "MedicalRecord": { "ID": "MED01", "Name": "Fasting Glucose Test", "Description":
    "Test Result for Fasting Glucose test is normal" } };
    json medicalRecordData2 = { "MedicalRecord": { "ID": "MED02", "Name": "Allergies", "Description":
    "Allergy condition recorded due to Summer allergies" } };
    response = sendPostRequest(medicalRecordEP, "/medical-record", medicalRecordData1);
    response = sendPostRequest(medicalRecordEP, "/medical-record", medicalRecordData2);

    log:printInfo("Adding Notification...");
    json notificationData1 = { "Notification": { "ID": "NOT01", "Name": "Lab Test Result Notification", "Description":
    "Test Result of Glucose test is ready" } };
    json notificationData2 = { "Notification": { "ID": "NOT02", "Name": "Flu Vaccine Status", "Description":
    "Flu vaccines due for this year" } };
    response = sendPostRequest(notificationEP, "/notification", notificationData1);
    response = sendPostRequest(notificationEP, "/notification", notificationData2);

    log:printInfo("Adding Messages...");
    json messageData1 = { "Message": { "ID": "MSG01", "From": "Dr. Caroline Caroline", "Subject":
    "Regarding Glucose test result", "Content": "Dear member, your test result remain normal", "Status": "Read" } };
    json messageData2 = { "Message": { "ID": "MSG02", "From": "Dr. Sandra Robert", "Subject": "Regarding flu season",
        "Content": "Dear member, We highly recommend you to get the flu vaccination to prevent yourself from flu",
        "Status": "Unread" } };
    json messageData3 = { "Message": { "ID": "MSG03", "From": "Dr. Peter Mayr", "Subject":
    "Regarding upcoming blood test", "Content": "Dear member, Your Glucose test is scheduled in early next month",
        "Status": "Unread" } };
    response = sendPostRequest(messageEP, "/message", messageData1);
    response = sendPostRequest(messageEP, "/message", messageData2);
    response = sendPostRequest(messageEP, "/message", messageData3);

    log:printInfo("Data publishing completed");
}

// Function which takes http client endpoint, context and data as a input
//This will perform a HTTP POST against given endpoint and return a json response
function sendPostRequest(http:Client clientEP, string context, json data) returns (json) {

    http:Client client1 = clientEP;

    http:Request req = new;
    req.setJsonPayload(data);

    var response = client1->post(context, req);

    json value = {};
    if (response is http:Response) {
        var msg = response.getJsonPayload();
        if (msg is json) {
            value = msg;
        } else {
            log:printError(msg.reason(), err = msg);
        }
    } else {
        log:printError(response.reason(), err = response);
    }
    return value;
}

// Function which takes http client endpoint and context as a input
// This will call given endpoint and return a json response
function sendGetRequest(http:Client httpClient1, string context) returns (json) {
    http:Client client1 = httpClient1;
    var response = client1->get(context);
    json value = {};

    if (response is http:Response) {
        var msg = response.getJsonPayload();
        if (msg is json) {
            value = msg;
        } else {
            log:printError(msg.reason(), err = msg);
        }
    } else {
        log:printError(response.reason(), err = response);
    }
    return value;
}
