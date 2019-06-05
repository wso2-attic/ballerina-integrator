import ballerina/test;
import ballerina/http;
import ballerina/io;

http:Client clientEP = new("http://localhost:9090/hello");

@test:BeforeSuite
function beforeSuite() {
//before test suit starts running
}

@test:Config {
    dataProvider: "helloServiceDataProvider"
}

//[postive]This function verifies for the response of the service.
//It asserts for the response text and the status code.
//Following function covers two test cases.
// TC001 - Verify the response when a valid name is sent.
// TC002 - Verify the response when a valid space string is sent as " ".
function testHelloServiceResponse(string name) {
    http:Request request = new;
    string payload = name;
    request.setPayload(payload);

    var response = clientEP->post("/sayHello ", request);

    if (response is http:Response) {
        test:assertEquals(response.getTextPayload(), "Hello " + name, msg = "assertion failed, name mismatch");
        test:assertEquals(response.statusCode, 200, msg = "Status Code mismatch!");
    } else {
        io:println("Response is not an http response");
    }
}

//This function passes data to testHelloServiceResponse function for two test cases.
function helloServiceDataProvider() returns (string[][]) {
    return [["John"], [" "]];
}

//Data provider for negative test cases.
@test:Config {
    dataProvider: "helloServiceDataProvider_negative"
}

//[negative]This function verifies the failure when an empty string is sent.
//This function covers the below test case.
// NTC001 - Verify the response when an invalid empty string is sent.
function testHelloServiceResponse_negative(string name) {
    http:Request request = new;
    string payload = name;
    request.setPayload(payload);

    var response = clientEP->post("/sayHello ", request);

    if (response is http:Response) {
        test:assertEquals(response.getTextPayload(), "Payload is empty ", msg = "assertion failed_negative");
    } else {
        io:println("Response is not an http response");
    }
}

//This function passes data to testHelloServiceResponse_negative function for two test cases.
function helloServiceDataProvider_negative() returns (string[][]) {
    return [[""]];
}

@test:AfterSuite
function afterSuite() {
//execute after running the test suite
}
