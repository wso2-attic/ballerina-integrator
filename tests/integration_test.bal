import ballerina/test;
import ballerina/io;
import ballerina/http;

boolean serviceStarted1;
boolean serviceStarted2;

@test:BeforeSuite
function startService() {
    serviceStarted1 = test:startServices("stock_quote_summary_service");
    serviceStarted2 = test:startServices("stock_quote_data_backend");
}

@test:Config
function testStockSummaryService() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9090"};
    // Chck whether the server is started
    test:assertTrue(serviceStarted1, msg = "Unable to start the service");
    test:assertTrue(serviceStarted2, msg = "Unable to start the service");

    json response1 = {"GOOG":"GOOG, Alphabet Inc., 1013.41", "APPL":"APPL, Apple Inc., 165.22", "MSFT":"MSFT, Microsoft Corporation, 95.35"};
    http:Request req = new;
    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/quote-summary", request = req);
    match response {
        http:Response resp => {
            var res = check resp.getJsonPayload();
            test:assertEquals(res, response1);
        }
        http:HttpConnectorError err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:AfterSuite
function stopService() {
    test:stopServices("stock_quote_summary_service");
}