// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/http;
import ballerina/io;
import wso2/healthcare;

http:Client healthCareEP = new("http://localhost:9092/healthcare");

# Description: This test scenario verifies new docotr can be added to a hospital. 
@test:Config{
    dataProvider: "testAddDoctorResponseDataProvider"
}
function testAddDoctor(json dataset, json resultset){
        http:Request request = new;
        request.setPayload(dataset);
        io:println("im addDoctor1");
        
        http:Response | error response = healthCareEP->post("/admin/newdoctor", request);

        if (response is http:Response){
            string | error responsePayload = response.getTextPayload();
            string expectedResponse = resultset.expectedResponse.toString();
            int | error expectedStatusCode = int.convert(resultset.expectedStatusCode);

            test:assertEquals(responsePayload, expectedResponse,msg = "Response mismatch!");
            test:assertEquals(response.statusCode, expectedStatusCode,msg = "Status Code mismatch");
        } else {
            test:assertFail(msg = "Error sending request");
        }
}

// This function passes data to testResourceAddAppoinment function for test cases.
function testAddDoctorResponseDataProvider() returns json[][] {
    return [
    // TC001 - Verify if a doctor can be added to Grand oak community hospital under the category surgery.
    [
    {
        "name": "T D Uyanage",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "Weekends",
        "fee": 2500.0
    },
    {
        "expectedResponse": "New Doctor Added Successfully.",
        "expectedStatusCode": 200
    }
    ],
    // TC002 - Verify if an existing doctor cannot be added. 
    [
    {
        "name": "T D Uyanage",
        "hospital": "clemency medical center",
        "category": "surgery",
        "availability": "Weekends",
        "fee": 2500.0
    },
    {
        "expectedResponse": "Doctor Already Exist in the system",
        "expectedStatusCode": 400
    }
    ]
    ];
}
