import ballerina/test;
import ballerina/http;
import ballerina/io;


// Start the filterService
@test:BeforeSuite 
function setupService () {
    _ = test:startServices("message-filtering");
}

// Client endpoint
endpoint http:Client clientEP {
    url:"http://localhost:9090/filterService"
};

// Function to test POST resource 'filterMarks' 
@test:Config
function testResourceFilterMarks () {

    // Initialize the empty http request
    http:Request req = new;
    // Construct the request payload
    json payload = {"students":[{"name":"Saman","subject":"Maths","marks":80},{"name":"Sugath","subject":"Maths","marks":34}]};
    // Set JSON payload to request
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response
    http:Response res = check clientEP -> post("/filterMarks", request = req);
    // Expected response code is 200
    test:assertEquals(res.statusCode, 200, msg = "filterMarks resource did not respond with expected response code!");
    // Get the response payload
    json resPayload = check res.getJsonPayload();
    // Get the student information
    json passStdInfo = resPayload.students[0];
    // Check whether the response is as expected
    test:assertEquals(passStdInfo.toString(), "{\"name\":\"Saman\",\"mark\":80}", msg = "Response mismatch!");

}


