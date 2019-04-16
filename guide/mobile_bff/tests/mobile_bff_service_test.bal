import ballerina/test;
import ballerina/http;
import ballerina/io;

// Client endpoint to communicate with mobile-bff service
http:Client clientEP = new("http://localhost:9090/mobile-bff");

@test:Config
// Function to test POST resource 'getUserProfile'.
function testResourceGetUserProfile() {
    var response = clientEP->get("/profile");

    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "getUserProfile resource did not respond with expected response code!");
    } else {
        test:assertFail(msg = "Client Responded with Error");   
    }
}
