import ballerina/test;
import ballerina/io;
import ballerina/http;

@test:Config
function testGoogResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};

    string response1 = "GOOG, Alphabet Inc., 1013.41";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/GOOG");
    match response {
        http:Response resp => {
            var res = check resp.getTextPayload();
            test:assertEquals(res, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testApplResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};

    string response2 = "APPL, Apple Inc., 165.22";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/APPL");
    match response {
        http:Response resp => {
            var res = check resp.getTextPayload();
            test:assertEquals(res, response2);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testMsftResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};

    string response2 = "MSFT, Microsoft Corporation, 95.35";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/MSFT");
    match response {
        http:Response resp => {
            var res = check resp.getTextPayload();
            test:assertEquals(res, response2);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:AfterSuite
function stopService() {
    test:stopServices("stock_quote_data_backend");
}
