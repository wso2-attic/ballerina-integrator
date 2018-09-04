import ballerina/test;
import ballerina/http;

// Client endpoint to communicate with medical record management service
endpoint http:Client clientEP {
    url: "http://localhost:9093/medical-records"
};

@test:Config
// Function to test POST resource 'addAppointment'.
function testResourceAddMedicalRecord() {
    // Initialize the empty http request.
    http:Request req = new;
    // Construct the request payload.
    json payload = { "MedicalRecord": { "ID": "MED01", "Name": "Test Record",
        "Description": "Test"}};
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    http:Response response = check clientEP -> post("/medical-record", req);
    // Expected response code is 201.
    test:assertEquals(response.statusCode, 201,
        msg = "addMedicalRecord resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(),
        "{\"status\":\"Medical Record Created.\",\"medicalRecordId\":\"MED01\"}"
        , msg = "Response mismatch!");
}

@test:Config {
    dependsOn:["testResourceAddMedicalRecord"]
}
// Function to test PUT resource 'updateOrder'.
function testResourceGetMedicalRecords() {
    // Send 'GET' request and obtain the response.
    http:Response response = check clientEP -> get("/medical-record/list");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getMedicalRecords resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(),
        "{\"MedicalRecords\":[{\"ID\":\"MED01\",\"Name\":\"Test Record\",\"Description\":\"Test\"}]}",
        msg = "Response mismatch!");
}

