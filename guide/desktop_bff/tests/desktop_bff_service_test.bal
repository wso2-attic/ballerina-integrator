import ballerina/test;
import ballerina/http;
import ballerina/io;

// Client endpoint to communicate with desktop-bff service
endpoint http:Client clientEP {
    url:"http://localhost:9091/desktop-bff"
};


@test:Config
// Function to test POST resource 'getAlerts'.
function testResourceGetAlerts() {
    http:Response response = check clientEP -> get("/alerts");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getAlerts resource did not respond with expected response code!");

    json resPayload = check response.getJsonPayload();
    io:println("########################");
    io:println(resPayload);
    io:println("########################");

}

@test:Config
// Function to test POST resource 'getAppointments'.
function testResourceGetAppointments() {
    http:Response response = check clientEP -> get("/appointments");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getAppointments resource did not respond with expected response code!");

}

@test:Config
// Function to test POST resource 'getMedicalRecords'.
function testResourceGetMedicalRecords() {
    http:Response response = check clientEP -> get("/medical-records");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getMedicalRecords resource did not respond with expected response code!");

}