// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/io;
http:Client clientEP = new("http://localhost:9092/hospitalMgtService/");

// Define the data provider for function testResourceAddAppoinment
@test:Config {
    dataProvider: "testResourceInsertDataProvider"
}

function testResourceAddAppoinment(json dataset) {
    // Initialize the empty http request.
    http:Request req = new;        
    json payload = dataset;    
    req.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/medicalreservation", req);
    if (response is http:Response) {
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201,
            msg = "Add appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {            
            test:assertEquals(dataset,resPayload,
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}   

// This function verifies for the response of the POST service.
// It asserts for the response text and the status code.
// Following function covers three test cases.
// TC001 - Verify the response when a valid request is sent.
// TC002 - Verify the response when a valid request is sent as " ".
// TC003 - Verify the response when a valid request is sent as empty json object.
// This function passes data to testResourceAddAppoinment function for test cases.
function testResourceInsertDataProvider() returns json[][]{
     return [[{ "Appoinment": { "ID": "001", "Name": "XYZ"} }],
            [{ "": { "": ""} }],
            [{}]];            
  }

// Define the data provider for function testResourceUpdateAppoinment_Negative
@test:Config {
    dataProvider: "testResourceUpdateDataProvider_Negative",
    dependsOn: ["testResourceAddAppoinment"]
}

function testResourceUpdateAppoinment_Negative(json dataset) {
    // Initialize empty http requests and responses.
    http:Request req = new;
    // Construct the request payload.
    json payload = dataset;
    req.setJsonPayload(payload);
    string testInput = payload.Appoinment.ID.toString();    
    // Send 'PUT' request and obtain the response.
    var response = clientEP->put("/medicalreservation/" + testInput, req);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "Update appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {                     
            test:assertEquals(resPayload,"Medical reservation : " + testInput + " cannot be found.",
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceUpdateAddAppoinment_Negative function for test cases.
// This negative function verifies the failure when an invalid ID is sent.
// This function covers the below test case.
// NTC001 - Verify the response when an invalid ID is sent.
function testResourceUpdateDataProvider_Negative() returns json[][]{
    return [[{ "Appoinment": { "ID": "002", "Name": "XYZAA"} }]];
}

// Define the data provider for function testResourceUpdateAddAppoinment
@test:Config {
    dataProvider: "testResourceUpdateDataProvider",
    dependsOn: ["testResourceAddAppoinment"]
}

function testResourceUpdateAppoinment(json dataset) {
    // Initialize empty http requests and responses.
    http:Request req = new;
    // Construct the request payload.
    json payload = dataset;
    req.setJsonPayload(payload);
    string testInput = payload.Appoinment.ID.toString();    
    // Send 'PUT' request and obtain the response.
    var response = clientEP->put("/medicalreservation/" + testInput, req);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "Update appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(dataset,resPayload,
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceUpdateAddAppoinment function for test cases.
// This negative function verifies the when an valid ID is sent.
// This function covers the below test case.
// TC004 - Verify the response when an valid ID is sent to update the details.
function testResourceUpdateDataProvider() returns json[][]{
    return [[{ "Appoinment": { "ID": "001", "Name": "XYZAA"} }]];
}

// Define the data provider for function testResourceGetDetails_Negative
@test:Config {
    dataProvider: "testResourceGetDataProvider_Negative",
    dependsOn: ["testResourceUpdateAppoinment"]
}

function testResourceGetDetails_Negative(json dataset) {    
    string testInput = dataset.Appoinment.ID.toString();
    var response = clientEP->get("/medicalreservation/" + testInput);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200, 
            msg = "Search appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {                       
            test:assertEquals(resPayload,"Medical reservation : " + testInput + " cannot be found.",
                 msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceGetDetails_Negative function for test cases.
// This negative function verifies the when an invalid ID is sent.
// This function covers the below test case.
// NTC002 - Verify the response when an invalid ID is sent.
function testResourceGetDataProvider_Negative() returns json[][] {
    return [[{ "Appoinment": { "ID": "002", "Name": "XYZAA"} }]];
    
}

// Define the data provider for function testResourceGetDetails.
@test:Config {
    dataProvider: "testResourceGetDataProvider",
    dependsOn: ["testResourceUpdateAppoinment"]
}

function testResourceGetDetails(json dataset) {
    string testInput = dataset.Appoinment.ID.toString();
    var response = clientEP->get("/medicalreservation/" + testInput);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200, 
            msg = "Search appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            string testresponseId = resPayload.Appoinment.ID.toString();            
            test:assertEquals(testresponseId,testInput,
                msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceGetDetails function for two test cases.
// This function verifies the when an valid ID is sent.
// This function covers the below test case.
// TC005 - Verify the response when an valid ID is sent.
function testResourceGetDataProvider() returns json[][] {
    return [[{ "Appoinment": { "ID": "001", "Name": "XYZAA"} }]];
}

@test:Config {
    dataProvider: "testResourceCancelDataProvider",
    dependsOn: ["testResourceGetDetails"]
}

// Function to test DELETE resource.
function testResourceCancelAppoinment(json dataset) {   
    http:Request req = new;    
    //string b = id;
    string testInput = dataset.Appoinment.ID.toString();
    var response = clientEP->delete("/medicalreservation/" + testInput, req);
    if (response is http:Response) {       
        test:assertEquals(response.statusCode, 200,
            msg = "cancelAppoinment resource did not respond with expected response code!");        
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {                        
            test:assertEquals(resPayload, "Medical reservation :  " + testInput + " removed.",
                  msg = "Response mismatch!");            
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceCancelAppoinment function for test cases.
// This function verifies the when an valid ID is sent.
// This function covers the below test case.
// TC006 - Verify the response when an valid ID is sent to delete the details.
function testResourceCancelDataProvider() returns json[][] {
    return [[{ "Appoinment": { "ID": "001", "Name": "XYZAA"} }]];
}
