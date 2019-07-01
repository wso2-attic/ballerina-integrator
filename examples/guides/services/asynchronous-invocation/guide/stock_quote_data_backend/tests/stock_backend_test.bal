import ballerina/test;
import ballerina/http;

@test:Config
function testGoogResource() {
    // Invoking the main function
    http:Client httpEndpoint = new("http://localhost:9095/nasdaq/quote");

    string expectedPayload = "GOOG, Alphabet Inc., 1013.41";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/GOOG");
    if (response is http:Response) {
        var res = response.getTextPayload();
        if (res is string) {
            test:assertEquals(res, expectedPayload);
        } else {
            test:assertFail(msg = "Failed to retrive the payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testApplResource() {
    // Invoking the main function
    http:Client httpEndpoint = new("http://localhost:9095/nasdaq/quote");

    string expectedPayload = "APPL, Apple Inc., 165.22";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/APPL");
    if (response is http:Response) {
        var res = response.getTextPayload();
        if (res is string) {
            test:assertEquals(res, expectedPayload);
        } else {
            test:assertFail(msg = "Failed to retrive the payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }
}

@test:Config
function testMsftResource() {
    // Invoking the main function
    http:Client httpEndpoint = new("http://localhost:9095/nasdaq/quote");

    string expectedPayload = "MSFT, Microsoft Corporation, 95.35";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint -> get("/MSFT");
    if (response is http:Response) {
        var res = response.getTextPayload();
        if (res is string) {
            test:assertEquals(res, expectedPayload);
        } else {
            test:assertFail(msg = "Failed to retrive the payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }
}

