import ballerina/test;
import ballerina/http;

// Client endpoint to communicate with notification management service
http:Client clientEP = new("http://localhost:9094/notification-mgt");

@test:Config
// Function to test POST resource 'addNotification'.
function testResourceAddNotification() {
    // Initialize the empty http request.
    http:Request req = new;
    // Construct the request payload.
    json payload = { "Notification": { "ID": "NOT01", "Name": "Test Notification", "Description": "Test" } };
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/notification", req);
    if (response is http:Response) {
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201,
            msg = "addNotification resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(),
                "{\"status\":\"Notification Created.\", \"notificationId\":\"NOT01\"}", msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "JSON Payload is expected");
        }
    } else {
        test:assertFail(msg = "Client Responded with Error");
    }
}

@test:Config {
    dependsOn: ["testResourceAddNotification"]
}
// Function to test PUT resource 'updateOrder'.
function testResourceGetNotifications() {
    // Send 'GET' request and obtain the response.
    var response = clientEP->get("/notification/list");
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "getNotifications resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(),
                "{\"Notifications\":[{\"ID\":\"NOT01\", \"Name\":\"Test Notification\", \"Description\":\"Test\"}]}",
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "JSON Payload is expected");
        }
    } else {
        test:assertFail(msg = "Client Responded with Error");
    }
}
