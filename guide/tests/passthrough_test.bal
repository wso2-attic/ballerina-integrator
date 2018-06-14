import ballerina/http;
import ballerina/io;
import ballerina/test;

boolean serviceStarted;

function startService() {
    serviceStarted = test:startServices("passthrough");
}

@test:Config {
    before: "startService",
    after: "stopService"
}

function testFunc() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");
    string response1="Welcome to WSO2 US head office!";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/LKSubOffice");

    match response {
        http:Response resp => {
            var Resp = check resp.getTextPayload();
            test:assertEquals(Resp, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function testFunc1() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9091" };
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");
    string response1="Welcome to WSO2 US head office!";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/UKSubOffice");

    match response {
        http:Response resp => {
            var Resp = check resp.getTextPayload();
            test:assertEquals(Resp, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}


function stopService() {
    test:stopServices("passthrough");
}