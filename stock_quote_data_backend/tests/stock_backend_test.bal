import ballerina/test;
import ballerina/io;
import ballerina/http;

boolean serviceStarted;

@test:BeforeSuite
function startService() {
    serviceStarted = test:startServices("stock_quote_data_backend");
}

@test:Config
function testGoogResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");

    string response1 = "GOOG, Alphabet Inc., 1013.41";
    http:Request req = new;
    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/GOOG", request = req);
    match response {
        http:Response resp => {
            var res = check resp.getStringPayload();
            test:assertEquals(res, response1);
        }
        http:HttpConnectorError err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testApplResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");

    string response2 = "APPL, Apple Inc., 165.22";
    http:Request req = new;
    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/APPL", request = req);
    match response {
        http:Response resp => {
            var res = check resp.getStringPayload();
            test:assertEquals(res, response2);
        }
        http:HttpConnectorError err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testMsftResource() {
    // Invoking the main function
    endpoint http:Client httpEndpoint {url:"http://localhost:9095/nasdaq/quote"};
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");

    string response2 = "MSFT, Microsoft Corporation, 95.35";
    http:Request req = new;
    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/MSFT", request = req);
    match response {
        http:Response resp => {
            var res = check resp.getStringPayload();
            test:assertEquals(res, response2);
        }
        http:HttpConnectorError err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:AfterSuite
function stopService() {
    test:stopServices("stock_quote_data_backend");
}