import ballerina/test;
import ballerina/io;
import ballerina/http;

// Common request Payload
json requestPayload = {
    "Item":"Car",
    "Condition":"good"
};

// Before Suite Function can be used to start the service
@test:BeforeSuite
function beforeFunc () {
    // Start the 'bidService' before running the test
    _ = test:startServices("bidders");
}

// Client endpoint
endpoint http:Client clientEP {
    url:"http://localhost:9091/bidders"
};

// Function to test resource 'bidder 1'
@test:Config
function testResourceBidder1 () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/bidder1", request = req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200,
        msg = "Bid service service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Bidder Name\":\"Bidder 1\",\"Bid\":350000}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}

// Function to test resource 'bidder 2'
@test:Config
function testResourceBidder2 () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/bidder2", request = req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200,
        msg = "Bid service service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Bidder Name\":\"Bidder 2\",\"Bid\":470000}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}

// Function to test resource 'bidder 3'
@test:Config
function testResourceBidder3 () {
    // Initialize the empty http requests and responses
    http:Request req;

    // Set request payload
    req.setJsonPayload(requestPayload);
    // Send a 'post' request and obtain the response
    http:Response response = check clientEP -> post("/bidder3", request = req);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200,
        msg = "Bid service service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    string expected = "{\"Bidder Name\":\"Bidder 3\",\"Bid\":440000}";
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(), expected, msg = "Response mismatch!");
}

@test:AfterSuite
function afterFunc () {
    // Stop the 'bidService' after running the test
    test:stopServices("bidders");
}
