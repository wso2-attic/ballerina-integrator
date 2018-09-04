import ballerina/test;
import ballerina/http;

// Client endpoint to communicate with appointment management service
endpoint http:Client clientEP {
    url: "http://localhost:9092/appointment-mgt"
};

@test:Config
// Function to test POST resource 'addAppointment'.
function testResourceAddAppointment() {
    // Initialize the empty http request.
    http:Request req = new;
    // Construct the request payload.
    json payload = { "Appointment": { "ID": "APT01", "Name": "Test Appointment", "Location": "Test Location",
        "Time":"2018-08-23, 08.30AM", "Description": "Test"}};
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    http:Response response = check clientEP -> post("/appointment", req);
    // Expected response code is 201.
    test:assertEquals(response.statusCode, 201,
        msg = "addAppointment resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(),
        "{\"status\":\"Appointment Created.\",\"appointmentId\":\"APT01\"}", msg = "Response mismatch!");
}

@test:Config {
    dependsOn:["testResourceAddAppointment"]
}
// Function to test PUT resource 'updateOrder'.
function testResourceGetAppointments() {
    // Send 'GET' request and obtain the response.
    http:Response response = check clientEP -> get("/appointment/list");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "addAppointment resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(),
        "{\"Appointments\":[{\"ID\":\"APT01\",\"Name\":\"Test Appointment\",\"Location\":\"Test Location\",\"Time\":\"2018-08-23, 08.30AM\",\"Description\":\"Test\"}]}",
        msg = "Response mismatch!");
}