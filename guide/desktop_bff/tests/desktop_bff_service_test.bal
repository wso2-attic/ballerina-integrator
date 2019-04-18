import ballerina/test;
import ballerina/http;
import ballerina/io;

// Client endpoint to communicate with desktop-bff service
http:Client clientEP = new("http://localhost:9091/desktop-bff");

@test:Config
// Function to test POST resource 'getAlerts'.
function testResourceGetAlerts() {
    var response = clientEP->get("/alerts");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200, 
        msg = "getAlerts resource did not respond with expected response code!");
    } else {
        test:assertFail(msg = "Client respond with error");
    }
}

@test:Config
// Function to test POST resource 'getAppointments'.
function testResourceGetAppointments() {
    var response = clientEP->get("/appointments");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
        msg = "getAppointments resource did not respond with expected response code!");    
    } else {
        test:assertFail(msg = "Client respond with error");
    }
}

@test:Config
// Function to test POST resource 'getMedicalRecords'.
function testResourceGetMedicalRecords() {
    var response = clientEP->get("/medical-records");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
        msg = "getMedicalRecords resource did not respond with expected response code!");    
    } else {
        test:assertFail(msg = "Client respond with error");
    }
}
