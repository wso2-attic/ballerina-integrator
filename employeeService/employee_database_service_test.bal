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

package employeeService;

import ballerina.net.http;
import ballerina.test;

string TEST_EMPLOYEE_ID = "879796979";

function testEmployeeDataService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9090/records", {});
    }
    // Initialize the empty http request and response
    http:OutRequest req = {};
    http:InResponse resp = {};
    // Start employee database service
    _ = test:startService("records");

    // Testing add new employee resource
    // Prepare sample employee and set the json payload
    json requestJson = {"Name":"Alice", "Age":"30", "SSN":"123456789", "EmployeeID":TEST_EMPLOYEE_ID};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp, _ = httpEndpoint.post("/employee", req);
    // Test the responses from the service with the original test data
    test:assertIntEquals(resp.statusCode, 200, "Add new employee resource did not reespond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload().Name.toString(), "Alice", "Name did not store in the database");

    // Testing retrieve by employee id resource
    // Prepare request with query parameter
    string url = "/employee?EmployeeID=" + TEST_EMPLOYEE_ID;
    // Send the request to service and get the response
    resp, _ = httpEndpoint.get(url, req);
    // Test the responses from the service with the original test data
    test:assertIntEquals(resp.statusCode, 200, "Add new employee resource did not reespond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload()[0].Name.toString(), "Alice", "recieved employee name not matched");

    // Testing update employee resource
    // Prepare sample employee and set the json payload
    requestJson = {"Name":"Alice Updated", "Age":"35", "SSN":"123456789", "EmployeeID":TEST_EMPLOYEE_ID};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp, _ = httpEndpoint.put("/employee", req);
    // Test the responses from the service with the updated test data
    test:assertIntEquals(resp.statusCode, 200, "Add new employee resource did not reespond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload().Name.toString(), "Alice Updated", "Name did not store in the database");

    // Testing delete employee resource
    // Prepare delete employee JSON
    requestJson = {"EmployeeID":TEST_EMPLOYEE_ID};
    //set the json payload to the request
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp, _ = httpEndpoint.delete("/employee", req);
    // Test whether the delete operation succeed
    test:assertIntEquals(resp.statusCode, 200, "Add new employee resource did not reespond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload()["Status"]["Status"].toString(), "Data Deleted Successfully",
                            "delete resource failed");
}
