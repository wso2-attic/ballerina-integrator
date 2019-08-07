import ballerina/test;
import ballerina/http;

@test:Config
function testStockSummaryService() {
    // Invoking the main function
    http:Client httpEndpoint = new("http://localhost:9090");

    json expectedPayload = { "GOOG": "Connection refused: localhost/127.0.0.1:9095",
        "APPL": "Connection refused: localhost/127.0.0.1:9095", "MSFT":
        "Connection refused: localhost/127.0.0.1:9095" };

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/quote-summary");
    if (response is http:Response) {
        var res = response.getJsonPayload();
        if (res is json) {
            test:assertEquals(res, expectedPayload);
        } else {
            test:assertFail(msg = "Failed to retrive the payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }
}
