// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

int TEST_EMPLOYEE_ID = 879796979;

// Create an endpoint with employee db service
http:Client httpEndpoint = new("http://localhost:9090/records");

@test:Config {
    dependsOn: ["testAddEmployeeResource"]
}
function testRetrieveByIdResource() {
    json expectedJson;
    // Testing retrieve by employee id resource
    // Prepare request with query parameter
    string url = "/employee/" + TEST_EMPLOYEE_ID;
    // Send the request to service and get the response
    var resp = httpEndpoint->get(url);
    if (resp is http:Response) {
        // Test the responses from the service with the original test data
        test:assertEquals(resp.statusCode, 200, msg =
            "Retreive employee resource did not reespond with 200 OK signal");
        var receivedPayload = resp.getJsonPayload();
        if (receivedPayload is json) {
            expectedJson = [{ "EmployeeID": 879796979, "Name": "Alice", "Age": 30, "SSN":
            123456789 }];
            test:assertEquals(receivedPayload[0], expectedJson[0], msg =
                "Name did not store in the database");
        } else {
            test:assertFail(msg = "Payload retrieval failed: " + <string>receivedPayload.detail().message);
        }
    } else {
        test:assertFail(msg = "Request failed: " + <string>resp.detail().message);
    }
}

@test:Config
function testAddEmployeeResource() {

    // Initialize the empty http request
    http:Request req = new;
    json expectedJson;

    // Testing add new employee resource
    // Prepare sample employee and set the json payload
    json requestJson = { "name": "Alice", "age": 30, "ssn": 123456789, "employeeId":
    TEST_EMPLOYEE_ID };
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    var resp = httpEndpoint->post("/employee", req);
    if (resp is http:Response) {
        // Test the response status code is correct
        test:assertEquals(resp.statusCode, 200, msg =
            "Add new employee resource did not reespond with 200 OK signal");
        // Test the responses from the service with the original test data
        var receivedPayload = resp.getJsonPayload();
        if (receivedPayload is json) {
            expectedJson = { "Status": "Data Inserted Successfully" };
            test:assertEquals(receivedPayload, expectedJson, msg =
                "Name did not store in the database");
        } else {
            test:assertFail(msg = "Payload retrieval failed: " + <string>receivedPayload.detail().message);
        }
    } else {
        test:assertFail(msg = "Request failed: " + <string>resp.detail().message);
    }
}

@test:Config {
    dependsOn: ["testAddEmployeeResource"]
}
function testUpdateEmployeeResource() {
    // Initialize the empty http request
    http:Request req = new;
    json expectedJson;

    // Testing update employee resource
    // Prepare sample employee and set the json payload
    json requestJson = { "name": "'Alice_Updated'", "age": 35, "ssn": 123456789,
        "employeeId": TEST_EMPLOYEE_ID };
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    var resp = httpEndpoint->put("/employee/", req);
    if (resp is http:Response) {
        // Test the responses from the service with the updated test data
        test:assertEquals(resp.statusCode, 200, msg =
            "Add new employee resource did not reespond with 200 OK signal");

        var receivedPayload = resp.getJsonPayload();
        if (receivedPayload is json) {
            expectedJson = { "Status": "Data Updated Successfully" };
            test:assertEquals(receivedPayload, expectedJson, msg =
                "Name did not updated in the database");
        } else {
            test:assertFail(msg = "Payload retrieval failed: " + <string>receivedPayload.detail().message);
        }
    } else {
        test:assertFail(msg = "Request failed: " + <string>resp.detail().message);
    }
}

@test:Config {
    dependsOn: ["testUpdateEmployeeResource", "testRetrieveByIdResource"]
}
function testDeleteEmployeeResource() {
    // Initialize the empty http request
    http:Request req = new;
    json expectedJson;

    // Testing delete employee resource
    // Send the request to service and get the response
    string url = "/employee/" + TEST_EMPLOYEE_ID;
    var resp = httpEndpoint->delete(url, req);
    if (resp is http:Response) {
        // Test whether the delete operation succeed
        test:assertEquals(resp.statusCode, 200, msg =
            "Delete employee resource did not reespond with 200 OK signal");

        var receivedPayload = resp.getJsonPayload();
        if (receivedPayload is json) {
            expectedJson = { "Status": "Data Deleted Successfully" };
            test:assertEquals(receivedPayload, expectedJson, msg = "Delete data resource failed");
        } else {
            test:assertFail(msg = "Payload retrieval failed: " + <string>receivedPayload.detail().message);
        }
    } else {
        test:assertFail(msg = "Request failed: " + <string>resp.detail().message);
    }
}
