import ballerina/test;
import ballerina/http;

// Client endpoint
http:Client clientEP = new("http://localhost:9090/filterService");

// Function to test POST resource 'filterMarks' 
@test:Config
function testResourceFilterMarks () {

    // Initialize the empty http request
    http:Request req = new;
    // Construct the request payload
    json payload = {"name":"Saman","subjects":[{"subject":"Maths","marks": 80},{"subject":"Science","marks":40}]};
    // Set JSON payload to request
    req.setJsonPayload(untaint payload);
    // Send 'POST' request and obtain the response
    var res = clientEP->post("/filterMarks", req);

    if (res is http:Response) {
        // Expected response code is 200
        test:assertEquals(res.statusCode, 200,
            msg = "filterMarks resource did not respond with expected response code!");
        // Get the response payload
        var resPayload = res.getJsonPayload();
        if (resPayload is json) {
            // Get the student information
            string status = <string>resPayload.status;
            // Check whether the response is as expected
            test:assertEquals(status, "Not Qualified", msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Response payload is not json");
        }
    } else {
        test:assertFail(msg = "Post request failed");
    }

}


