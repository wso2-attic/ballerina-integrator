package guide.restful_service;

import ballerina.test;
import ballerina.net.http;

// Create HTTP Client
http:HttpClient httpClient = create http:HttpClient("http://localhost:9090/ordermgt", {});

function beforeTest () {
    // Start the 'OrderMgtService' before running the test
    _ = test:startService("OrderMgtService");
}

// Function to test resource 'addOrder' - POST method
function testResourceAddOrder () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Construct the request payload
    json payload = {"Order":{"ID":"100500", "Name":"XYZ", "Description":"Sample order."}};
    request.setJsonPayload(payload);
    // Send a 'POST' request and obtain the response
    response, err = httpEndpoint.post("/order", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Failed to add new order!");
    // Expected response code is 201
    test:assertIntEquals(response.statusCode, 201, "addOrder resource did not respond with expected response code!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(), "{\"status\":\"Order Created.\"," +
                                                                  "\"orderId\":\"100500\"}", "Response mismatch!");
}

// Function to test resource 'updateOrder' - PUT method
function testResourceUpdateOrder () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Construct the request payload
    json payload = {"Order":{"Name":"XYZ", "Description":"Updated order."}};
    request.setJsonPayload(payload);
    // Send a 'PUT' request and obtain the response
    response, err = httpEndpoint.put("/order/100500", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Failed to update the order!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "updateOrder resource did not respond with expected response code!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(), "{\"Order\":{\"ID\":\"100500\",\"Name\":\"XYZ\"," +
                                                                  "\"Description\":\"Updated order.\"}}",
                            "Response mismatch!");

}

// Function to test resource 'findOrder' - GET method
function testResourceFindOrder () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Send a 'GET' request and obtain the response
    response, err = httpEndpoint.get("/order/100500", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Failed to retrive the order!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "findOrder resource did not respond with expected response code!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(), "{\"Order\":{\"ID\":\"100500\",\"Name\":\"XYZ\"," +
                                                                  "\"Description\":\"Updated order.\"}}",
                            "Response mismatch!");
}

// Function to test resource 'cancelOrder' - DELETE method
function testResourceCancelOrder () {
    endpoint<http:HttpClient> httpEndpoint {
        httpClient;
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Send a 'DELETE' request and obtain the response
    response, err = httpEndpoint.delete("/order/100500", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Failed to cancel the order!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "cancelOrder resource did not respond with expected response code!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(), "Order : 100500 removed.",
                            "Response mismatch!");
}

