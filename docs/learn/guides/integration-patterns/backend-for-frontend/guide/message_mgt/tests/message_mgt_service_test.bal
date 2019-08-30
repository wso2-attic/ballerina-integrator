import ballerina/test;
import ballerina/http;

// Client endpoint to communicate with message management service
http:Client clientEP = new("http://localhost:9095/message-mgt");

@test:Config
// Function to test POST resource 'addMessage'.
function testResourceAddMessage() {
    // Initialize the empty http request.
    http:Request req = new;
    // Construct the request payload.
    json payload = { "Message": { "ID": "MSG01", "From": "Dr. Carl",
        "Subject": "Test Msg", "Content": "Test", "Status": "Read" } };
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/message", req);
    if (response is http:Response) {
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201,
            msg = "addMessage resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(),
                "{\"status\":\"Message Sent.\", \"messageId\":\"MSG01\"}", msg = "Response mismatch!");     
        } else {
            test:assertFail(msg = "Response Payload is not JSON");
        }   
    } else {
        test:assertFail(msg = "Client responded with Error");
    }
}

@test:Config {
    dependsOn: ["testResourceAddMessage"]
}
// Function to test PUT resource 'getMessages'.
function testResourceGetMessages() {
    // Send 'GET' request and obtain the response.
    var response = clientEP->get("/message/list");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "getMessages resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(),
                "{\"Messages\":[{\"ID\":\"MSG01\", \"From\":\"Dr. Carl\", \"Subject\":\"Test Msg\", " +
                "\"Content\":\"Test\", \"Status\":\"Read\"}]}"
                ,
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Response Payload is not JSON");
        }
    } else {
        test:assertFail(msg = "Client responded with Error");
    }
}
