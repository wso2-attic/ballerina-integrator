import ballerina/test;
import ballerina/io;
import ballerina/http;

@test:Config
function testStockSummaryService() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };

    json response1 = { "GOOG": "Connection refused: localhost/127.0.0.1:9095",
        "APPL": "Connection refused: localhost/127.0.0.1:9095", "MSFT":
        "Connection refused: localhost/127.0.0.1:9095" };

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/quote-summary");
    match response {
        http:Response resp => {
            var res = check resp.getJsonPayload();
            test:assertEquals(res, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}
