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
import wso2/healthcare as _;

http:Client clientEP = new("http://localhost:9092/hospitalMgtService");

@test:Config {
    dataProvider: "testReservationDataProvider"
}
function testReservation(json dataset, json resultset) {
    http:Request req = new;
    req.setJsonPayload(dataset);
    req.addHeader("content-type", "application/json");
    var response = clientEP->post("/categories/surgery/reserve", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200,
            msg = "Reserve-Appointment service did not respond with 200 OK signal!");
        string | error receivedPayload = response.getTextPayload();
        if (receivedPayload is string) {
            var resPayload = response.getJsonPayload();
            if (resPayload is json) {
                test:assertEquals(resPayload, resultset, msg = "Response mismatch!");
            } else {
                test:assertFail(msg = "Payload from reservation service is invalid");
            }
        } else {
            test:assertFail(msg = "Response is an error");
        }
    } else {
        test:assertFail(msg = "Response from reservation service is invalid");
    }
}

function testReservationDataProvider() returns json[][] {
    return 
    [
        [
            {
                "patient": {
                    "name": "John Doe",
                    "dob": "1940-03-19",
                    "ssn": "234-23-525",
                    "address": "California",
                    "phone": "8770586755",
                    "email": "johndoe@gmail.com"
                },
                "doctor": "thomas collins",
                "hospital": "grand oak community hospital",
                "appointmentDate": "2025-04-02"
            },
            {
                "appointmentNumber": 1,
                "appointmentDate": "2025-04-02",
                "doctor": {
                    "name": "thomas collins",
                    "hospital": "grand oak community hospital",
                    "category": "surgery",
                    "availability": "9.00 a.m - 11.00 a.m",
                    "fee": 7000.0
                },
                "patient": {
                    "name": "John Doe",
                    "dob": "1940-03-19",
                    "ssn": "234-23-525",
                    "address": "California",
                    "phone": "8770586755",
                    "email": "johndoe@gmail.com"
                },
                "fee": 7000.0,
                "confirmed": false
            }
        ]
    ];
}
