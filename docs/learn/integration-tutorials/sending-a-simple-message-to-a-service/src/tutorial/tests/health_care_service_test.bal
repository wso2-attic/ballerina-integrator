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
import wso2/healthcare as _;

http:Client clientEP = new("http://localhost:9092/hospitalMgtService");

// Define the data provider for function testResourceGetDetails.
@test:Config {
    dataProvider: "testGetDetailsDataProvider"
}
function testGetDetails(json dataset, json resultset) {
    string category = dataset.category.toString();
    var response = clientEP->get("/getdoctor/" + category);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200, 
            msg = "Search appoinment resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
            test:assertEquals(responsePayload, resultset,msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testGetDetailsDataProvider() returns json[][] {
    return 
    [
        [
            {
                "category": "surgery"
            },
            [
                {
                    "name": "anne clement",
                    "hospital": "clemency medical center",
                    "category": "surgery",
                    "availability": "8.00 a.m - 10.00 a.m",
                    "fee": 12000.0
                },
                {
                    "name": "thomas collins",
                    "hospital": "grand oak community hospital",
                    "category": "surgery",
                    "availability": "9.00 a.m - 11.00 a.m",
                    "fee": 7000.0
                },
                {
                    "name": "seth mears",
                    "hospital": "pine valley community hospital",
                    "category": "surgery",
                    "availability": "3.00 p.m - 5.00 p.m",
                    "fee": 8000.0
                }
            ]
        ]
    ];
}


