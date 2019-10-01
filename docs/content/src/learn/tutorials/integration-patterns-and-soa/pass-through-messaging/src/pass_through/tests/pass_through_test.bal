import ballerina/http;
import ballerina/test;

@test:Config {}
function testFunc() {
    // Invokes the main function
    http:Client httpEndpoint = new("http://localhost:9090");

    string responseText = "Welcome to Local Shop! Please put your order here.....";

    // Sends a GET request to the specified endpoint.
    var response = httpEndpoint->get("/OnlineShopping");
    if(response is http:Response) {
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, responseText);
        } else {
            test:assertFail(msg = "Failed to parse the text payload");
        }
    } else {
        test:assertFail(msg = "Failed to call the endpoint");
    }
}
