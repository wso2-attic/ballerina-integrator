import ballerina/http;
import ballerina/io;
import ballerina/test;

function startService() {
}

@test:Config {
    before: "startService",
    after: "stopService"
}
function testFunc() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };

    string response1 = "Welcome to Local Shop! Please put your order here.....";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/OnlineShopping");

    match response {
        http:Response resp => {
            var Resp = check resp.getTextPayload();
            test:assertEquals(Resp, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}


function stopService() {
}
