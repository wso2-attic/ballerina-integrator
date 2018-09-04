import ballerina/test;
import ballerina/http;
import ballerina/io;

// Client endpoint to communicate with mobile-bff service
endpoint http:Client clientEP {
    url:"http://localhost:9090/mobile-bff"
};


@test:Config
// Function to test POST resource 'getUserProfile'.
function testResourceGetUserProfile() {
    http:Response response = check clientEP -> get("/profile");
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "getUserProfile resource did not respond with expected response code!");

    json resPayload = check response.getJsonPayload();
    io:println("########################");
    io:println(resPayload);
    io:println("########################");


}