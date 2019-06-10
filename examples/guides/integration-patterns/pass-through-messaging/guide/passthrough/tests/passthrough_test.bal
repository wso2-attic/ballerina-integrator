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
    // Invokes the main function
    http:Client httpEndpoint = new("http://localhost:9090");

    string response1 = "Welcome to Local Shop! Please put your order here.....";

    // Sends a GET request to the specified endpoint.
    var response = httpEndpoint->get("/OnlineShopping");
    if(response is http:Response) {
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, response1);
        } else {
            test:assertFail(msg = "Failed to parse the text payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint");
    }
}


function stopService() {
}
