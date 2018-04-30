import ballerina/test;
import ballerina/io;
import ballerina/http;

boolean serviceStarted;

@test:BeforeSuite
function startService() {
    serviceStarted = test:startServices("stock_quote_summary_service");
}

@test:Config
function testStockSummaryService() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");

    json response1 = { "GOOG": "Connection refused: localhost/127.0.0.1:9095",
        "APPL": "Connection refused: localhost/127.0.0.1:9095", "MSFT":
        "Connection refused: localhost/127.0.0.1:9095" };
    http:Request req = new;
    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/quote-summary", request = req);
    match response {
        http:Response resp => {
            var res = check resp.getJsonPayload();
            test:assertEquals(res, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:AfterSuite
function stopService() {
    test:stopServices("stock_quote_summary_service");
}