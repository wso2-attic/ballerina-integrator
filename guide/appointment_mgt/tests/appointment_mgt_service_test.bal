import ballerina/test;
import ballerina/http;

// Client endpoint to communicate with appointment management service
http:Client clientEP = new("http://localhost:9092/appointment-mgt");

@test:Config
// Function to test POST resource 'addAppointment'.
function testResourceAddAppointment() {
    // Initialize the empty http request.
    http:Request req = new;
    // Construct the request payload.
    json payload = { "Appointment": { "ID": "APT01", "Name": "Test Appointment", "Location": "Test Location",
        "Time": "2018-08-23, 08.30AM", "Description": "Test" } };
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/appointment", req);

    if (response is http:Response) {
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201, 
        msg = "addAppointment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), 
            "{\"status\":\"Appointment Created.\", \"appointmentId\":\"APT01\"}", msg = "Response mismatch!");    
        } else {
            test:assertFail(msg = "Response Payload is not JSON");
        }        
    } else {
        test:assertFail(msg = "Client responded with an error");
    }

}

@test:Config {
    dependsOn: ["testResourceAddAppointment"]
}
// Function to test PUT resource 'updateOrder'.
function testResourceGetAppointments() {
    // Send 'GET' request and obtain the response.
    var response = clientEP->get("/appointment/list");

    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200, 
        msg = "addAppointment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();

        if (resPayload is json) {
            test:assertEquals(resPayload.toString(), 
            "{\"Appointments\":[{\"ID\":\"APT01\", \"Name\":\"Test Appointment\", \"Location\":\"Test Location\", " 
            + "\"Time\":\"2018-08-23, 08.30AM\", \"Description\":\"Test\"}]}", msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Response Payload is not JSON");
        }
        
    } else {
        test:assertFail(msg = "Client respond with error");
    }
}
