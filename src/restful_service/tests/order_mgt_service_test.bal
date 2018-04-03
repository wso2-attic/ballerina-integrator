package restful_service;

import ballerina/test;
import ballerina/net.http;

@test:BeforeSuite
function beforeFunc () {
    // Start the 'OrderMgtService' before running the test
    _ = test:startServices("restful_service");
}

endpoint http:ClientEndpoint clientEP {
    targets:[{uri:"http://localhost:9090/ordermgt"}]
};

@test:Config
// Function to test resource 'addOrder' - POST method
function testResourceAddOrder () {
    // Initialize the empty http request
    http:Request request = {};
    // Construct the request payload
    json payload = {"Order":{"ID":"100500", "Name":"XYZ", "Description":"Sample order."}};
    request.setJsonPayload(payload);
    // Send a 'POST' request and obtain the response
    http:Response response =? clientEP -> post("/order", request);
    // Expected response code is 201
    test:assertEquals(response.statusCode, 201, msg = "addOrder resource did not respond with expected response code!");
    // Check whether the response is as expected
    json responsePayload =? response.getJsonPayload();
    test:assertEquals(responsePayload.toString(), "{\"status\":\"Order Created.\"," +
                                                  "\"orderId\":\"100500\"}", msg = "Response
                                                                  mismatch!");
}

@test:Config {
    dependsOn:["testResourceAddOrder"]
}
// Function to test resource 'updateOrder' - PUT method
function testResourceUpdateOrder () {
    // Initialize the empty http requests and responses
    http:Request request = {};
    // Construct the request payload
    json payload = {"Order":{"Name":"XYZ", "Description":"Updated order."}};
    request.setJsonPayload(payload);
    // Send a 'PUT' request and obtain the response
    http:Response response =? clientEP -> put("/order/100500", request);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "updateOrder resource did not respond with expected response
    code!");
    // Check whether the response is as expected
    json responsePayload =? response.getJsonPayload();
    test:assertEquals(responsePayload.toString(), "{\"Order\":{\"ID\":\"100500\",\"Name\":\"XYZ\"," +
                                                  "\"Description\":\"Updated order.\"}}",
                      msg = "Response mismatch!");

}

@test:Config {
    dependsOn:["testResourceUpdateOrder"]
}
// Function to test resource 'findOrder' - GET method
function testResourceFindOrder () {
    // Initialize the empty http requests and responses
    http:Request request = {};
    // Send a 'GET' request and obtain the response
    http:Response response =? clientEP -> get("/order/100500", request);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "findOrder resource did not respond with expected response
    code!");
    // Check whether the response is as expected
    json responsePayload =? response.getJsonPayload();
    test:assertEquals(responsePayload.toString(), "{\"Order\":{\"ID\":\"100500\",\"Name\":\"XYZ\"," +
                                                  "\"Description\":\"Updated order.\"}}",
                      msg = "Response mismatch!");
}

@test:Config {
    dependsOn:["testResourceFindOrder"]
}
// Function to test resource 'cancelOrder' - DELETE method
function testResourceCancelOrder () {
    // Initialize the empty http requests and responses
    http:Request request = {};
    // Send a 'DELETE' request and obtain the response
    http:Response response =? clientEP -> delete("/order/100500", request);
    // Expected response code is 200
    test:assertEquals(response.statusCode, 200, msg = "cancelOrder resource did not respond with expected response
    code!");
    // Check whether the response is as expected
    json responsePayload =? response.getJsonPayload();
    test:assertEquals(responsePayload.toString(), "Order : 100500 removed.",
                      msg = "Response mismatch!");
}

@test:AfterSuite
function afterFunc () {
    // Stop the 'OrderMgtService' after running the test
    test:startServices("restful_service");
}
