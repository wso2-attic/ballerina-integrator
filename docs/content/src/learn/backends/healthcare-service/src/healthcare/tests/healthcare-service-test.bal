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
import ballerina/time;

http:Client healthCareEP = new("http://localhost:9095/healthcare");

# Description: This test scenario verifies new docotr can be added to a hospital. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testAddDoctorResponseDataProvider"
}
function testAddDoctor(json dataset, json resultset) {
    // set the json payload
    http:Request request = new;
    request.setPayload(dataset);

    // sending the post request
    http:Response | error response = healthCareEP->post("/admin/newdoctor", request);

    if (response is http:Response) {
        string | error responsePayload = response.getTextPayload();
        string expectedResponse = resultset.expectedResponse.toString();
        var expectedStatusCode = resultset.expectedStatusCode;

        test:assertEquals(responsePayload, expectedResponse,msg = "Response mismatch!");
        test:assertEquals(response.statusCode, expectedStatusCode,msg = "Status Code mismatch");
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// This function passes data to testResourceAddAppoinment function for test cases.
function testAddDoctorResponseDataProvider() returns json[][] {
    return 
    [
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
        ],
        // TC003 - Verify if a doctor can be added under a new category.
        [
            {
                "name": "H Dias",
                "hospital": "clemency medical center",
                "category": "emergency",
                "availability": "Sunday only",
                "fee": 2500.0
            },
            {
                "expectedResponse": "New Doctor Added Successfully.",
                "expectedStatusCode": 200
            }
        ]
    ];
}

# Description: This test scenario verifies if a doctor record can be retrived. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testGetDoctorsDataProvider",
    dependsOn: ["testAddDoctor"]
}
function testGetDoctors(json dataset, json resultset) {
    string inputCategory = dataset.category.toString();
    http:Response | error response = healthCareEP->get("/queryDoctor/" + inputCategory + "/");

    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
             test:assertEquals(responsePayload, resultset, msg = "Response mismatch!");     
        } else {
            test:assertFail(msg = "Invalid Payload!");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testGetDoctorsDataProvider() returns json[][]
{
    return 
    [
    // TC004 - Verify if added doctor record under TC001 can be retrived under category surgery.
        [
            {
                "category": "surgery",
                "doctor": "T D Uyanage"
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
                },
                {
                    "name": "T D Uyanage",
                    "hospital": "grand oak community hospital",
                    "category": "surgery",
                    "availability": "Weekends",
                    "fee": 2500.0
                }
            ]
        ]
    ];
}

# Description: This test scenario verifies if it can retreive the details of appointments.
# + dataset - dataset Parameter Description 
# + resultset - resultset Parameter Description
@test:Config {
    dataProvider: "testGetAppointmentDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testGetAppointment(json dataset, json resultset) {
    string inputAppointmentNumber = dataset.appointmentNumber.toString();
    http:Response | error response = healthCareEP->get("/appointments/" + inputAppointmentNumber);

    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
            test:assertEquals(responsePayload, resultset, msg = "Assertion Failed!, json payload mismatch");
        } else {
            test:assertFail(msg = "Invalid Payload!");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }

}

function testGetAppointmentDataProvider() returns json[][]
{
    return 
    [
    // TC005 - verify if appointment details can be retreived.
        [
            {
                "appointmentNumber": 1
            },
            {
                "appointmentNumber": 1,
                "doctor":{
                    "name": "anne clement",
                    "hospital": "clemency medical center",
                    "category": "surgery",
                    "availability": "8.00 a.m - 10.00 a.m",
                    "fee": 12000.0
                },
                "patient":{
                    "name": "Leonardo Duke",
                    "dob": "1988-03-19",
                    "ssn": "111-23-505",
                    "address": "NY",
                    "phone": "8070586755",
                    "email": "jduke@gmail.com"
                },
                "fee": 12000.0,
                "confirmed": true,
                "appointmentDate": "2019-07-02"
            }
        ]
    ];
}

# Description: This test scenario verifies the validity of the appointment date.
# + dataset - dataset Parameter Description 
@test:Config {
    dataProvider: "testGetAppointmentValidityTimeDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testGetAppointmentValidityTime(json dataset) {
    string inputAppointmentNumber = dataset.appointmentNumber.toString();

    // getting the expected validity days
    http:Response | error response = healthCareEP->get("/appointments/" + inputAppointmentNumber);
    int expectedValidityDays = 0;
    if (response is http:Response) {
        var responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
            string appointmentDateFromPayload = responsePayload.appointmentDate.toString();
            var date = time:parse(appointmentDateFromPayload, "yyyy-MM-dd");
            if (date is time:Time) {
                time:Time today = time:currentTime();
                // Get no of days remaining for the appointment.
                expectedValidityDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
            } else {
                test:assertFail(msg = "Test Failed for invalid date");
            }
        } else {
            test:assertFail(msg = "Invalid Payload!");
        }
    } else {
        test:assertFail(msg = "Error sending request to get appointment details");
    }

    // getting the actual validity days
    http:Response | error responseValidity = healthCareEP->get("/appointments/validity/" + inputAppointmentNumber);
    if (responseValidity is http:Response) {
        var responsePayloadActual = responseValidity.getJsonPayload();
        if (responsePayloadActual is json) {
            test:assertEquals(responsePayloadActual, expectedValidityDays, 
                                        msg = "Number of validity days of the appointment is not as expected");
        } else {
            test:assertFail(msg = "Invalid Payload!");
        }
    } else {
        test:assertFail(msg = "Error sending request in getting actual validity days");
    }
}

function testGetAppointmentValidityTimeDataProvider() returns json[][]
{
    return 
    [
    // TC006 - verify if the provided appointment date is valid.
        [
            {
                "appointmentNumber": 1
            }
        ]
    ];
}

# Description: This test scenario verifies if the appointments can be removed.
# + dataset - dataset Parameter Description 
@test:Config {
    dataProvider: "testRemoveAppointmentDataProvider",
    dependsOn: ["testIsEligibleForDiscountGrandoaks"]
}
function testRemoveAppointment(json dataset) {
    string inputAppointmentNumber = dataset.appointmentNumber.toString();
    http:Response | error response = healthCareEP->delete("/appointments/"
    + inputAppointmentNumber, "Remove Appointment");
    if (response is http:Response) {
        string | error actualResponse = response.getTextPayload();
        json | error expectedResponse = dataset.response;
        test:assertEquals(actualResponse, expectedResponse, msg = "Response message as not as expected!");
    } else {
        test:assertFail(msg = "Error sending request!");
    }
}

function testRemoveAppointmentDataProvider() returns json[][]
{
    return 
    [
    // TC007 - verify if appointments can be deleted.
        [
            {
                "appointmentNumber": 6,
                "response": "Appointment is successfully removed."
            }
        ]
    ];
}

# Description: This test scenario verifies payments can be settled successfully. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testSettlePaymentDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testSettlePayment(json dataset) {
    http:Request request = new;
    request.setPayload(dataset);

    http:Response | error response = healthCareEP->post("/payments", request);
    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if(responsePayload is json){
            boolean isSuccessfullySettled = false;
            map<json>|error responsePayloadMap = map<json>.constructFrom(responsePayload);
            if(responsePayloadMap is map<json>)
            {
                if (responsePayloadMap["status"] == "success")
                {
                    isSuccessfullySettled = true;
                    test:assertEquals(isSuccessfullySettled, true, 
                                              msg = "The payment settlement is not as expected!");
                }
                else{
                    test:assertFail(msg = "Response does not contain the exact response message");
                }
            }else{
                test:assertFail(msg = "responsePayloadMap is invalid");
            }
        }else{
            test:assertFail(msg = "Invalid Payload!");
        }
    }else {
        test:assertFail(msg = "Error sending request!");
    }
}

function testSettlePaymentDataProvider() returns json[][]
{
    return 
    [
    // TC008 - verify if payment can be setteled for a given appointment.
        [
            {
                "appointmentNumber": 1,
                "doctor":{
                    "category": "surgery",
                    "name": "anne clement",
                    "hospital": "clemency medical center",
                    "availability": "10am - 6pm",
                    "fee": 10000.00
                },
                "patient":{
                    "name": "Kate Winslet",
                    "dob": "1970-03-19",
                    "ssn": "234-987-175",
                    "address": "Canada",
                    "phone": "32456789765",
                    "email": "kwinslet@gmail.com"
                },
                "fee": 1800.0,
                "confirmed": true,
                "cardNumber": "3456812345"
            }
        ]
    ];
}
