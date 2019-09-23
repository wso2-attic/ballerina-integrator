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

http:Client clientEPclemency = new("http://localhost:9095/clemency/categories");

# Description: This test verifies if an appointment can be reserved successfully. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testReserveAppointmentDataProvider",
    dependsOn: ["testAddDoctor"]
}
function testReserveAppointment(json dataset, json resultSet) {
    // set the json payload
    http:Request request = new;
    request.setPayload(dataset);

    // sending the post request to the endpoint
    http:Response | error response = clientEPclemency->post("/surgery/reserve", request);

    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        var expectedStatusCode = 200;

        if (responsePayload is json) {
            test:assertEquals(response.statusCode, expectedStatusCode, msg = "Status Code mismatch!");
            test:assertEquals(responsePayload, resultSet, msg = "Expected payload is different than the actual");
        } else {
            test:assertFail(msg = "Test Failed!, Invalid Payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testReserveAppointmentDataProvider() returns json[][]
{
    return 
    [
    // TC001 - Verify if appointment reservation can be done by providing all the valid inputs.
        [
            {
                "patient": {
                    "name": "Leonardo Duke",
                    "dob": "1988-03-19",
                    "ssn": "111-23-505",
                    "address": "NY",
                    "phone": "8070586755",
                    "email": "jduke@gmail.com"
                },
                "doctor": "anne clement",
                "hospital": "clemency medical center",
                "appointmentDate": "2019-07-02"
            },
            {
            "appointmentNumber": 1,
            "doctor": {
                "name": "anne clement",
                "hospital": "clemency medical center",
                "category": "surgery",
                "availability": "8.00 a.m - 10.00 a.m",
                "fee": 12000.0
            },
            "patient": {
                "name": "Leonardo Duke",
                "dob": "1988-03-19",
                "ssn": "111-23-505",
                "address": "NY",
                "phone": "8070586755",
                "email": "jduke@gmail.com"
            },
            "fee": 12000.0,
            "confirmed": false,
            "appointmentDate": "2019-07-02"
            }
        ],
    // TC002 - Verify if appointment reservation can be done by not providing non-mandatory feilds.
        [
            {
                "patient": {
                    "name": "J Serasinghe",
                    "dob": "1951-03-19",
                    "ssn": "112-29-585",
                    "address": "California",
                    "phone": "8070521755",
                    "email": ""
                },
                "doctor": "thomas kirk",
                "hospital": "clemency medical center",
                "appointmentDate": "2019-08-30"
            },
            {
            "appointmentNumber": 2,
            "doctor": {
                "name": "thomas kirk",
                "hospital": "clemency medical center",
                "category": "gynaecology",
                "availability": "9.00 a.m - 11.00 a.m",
                "fee": 8000.0
            },
            "patient": {
                "name": "J Serasinghe",
                "dob": "1951-03-19",
                "ssn": "112-29-585",
                "address": "California",
                "phone": "8070521755",
                "email": ""
            },
            "fee": 8000.0,
            "confirmed": false,
            "appointmentDate": "2019-08-30"
            }
        ],
    // TC003 - Verify if appointment reservation can be made for a child.
        [
            {
                "patient": {
                    "name": "Little John",
                    "dob": "2018-04-29",
                    "ssn": "",
                    "address": "California",
                    "phone": "",
                    "email": ""
                },
                "doctor": "cailen cooper",
                "hospital": "clemency medical center",
                "appointmentDate": "2019-12-02"
            },
            {
            "appointmentNumber": 3,
            "doctor": {
                "name": "cailen cooper",
                "hospital": "clemency medical center",
                "category": "paediatric",
                "availability": "9.00 a.m - 11.00 a.m",
                "fee": 5500.0
            },
            "patient": {
                "name": "Little John",
                "dob": "2018-04-29",
                "ssn": "",
                "address": "California",
                "phone": "",
                "email": ""
            },
            "fee": 5500.0,
            "confirmed": false,
            "appointmentDate": "2019-12-02"
            }
        ]
    ];
}

# Description: This test verifies if an error occurs when appointment reservation is done for an 
# unavilable doctor in clemency hospital. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testReserveAppointmentNegativeDataProvider",
    dependsOn: ["testAddDoctor"]
}
function testReserveAppointmentNegative(json dataset, json expectedStrings) {
    http:Request request = new;
    request.setPayload(dataset);

    // sending the post request to the endpoint
    http:Response | error response = clientEPclemency->post("/surgery/reserve", request);
    if (response is http:Response) {
        string doctor = dataset.doctor.toString();
        var expectedResponseText = expectedStrings.responseMessage;
        var expectedStatusCode = expectedStrings.statusCode;

        string | error responsePayload = response.getTextPayload();
        var responseStatusCode = response.statusCode;

        test:assertEquals(responsePayload, expectedResponseText, 
                                                            msg = "Assertion Failed for Doctor " + doctor);
        test:assertEquals(responseStatusCode, expectedStatusCode, msg = "Status code mismatch!");
    }
    else
    {
        test:assertFail(msg = "Error sending request");
    }
}

function testReserveAppointmentNegativeDataProvider() returns json[][] {
    return 
    [
    // TC004 - Verify if an error message is thrown when appointment reservation can be done for an
    // unavailable doctor in the hospital.
        [
            {
                "patient": {
                    "name": "D Serasinghe",
                    "dob": "1983-12-03",
                    "ssn": "777-29-585",
                    "address": "Colombo SL",
                    "phone": "5578521755",
                    "email": "dserasinghe@hotmail.com"
                },
                "doctor": "T Uyanage",
                "hospital": "clemency medical center",
                "appointmentDate": "2019-12-31"
            },
            {
                "statusCode": 400,
                "responseMessage": "Doctor T Uyanage is not available in clemency medical center"
            }
        ]
    ];
}

# Description: This test scenario verifies if details of the reserved appoinment can be retrived. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testGetAppointmentClemencyDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testGetAppointmentClemency(json dataset) {
    var expectedAppointmentNumber = dataset.appointmentNumber;
    string expectedDoctorName = dataset.doctorName.toString();
    string expectedAppointmentDate = dataset.appointmentDate.toString();

    http:Response | error response = clientEPclemency->get("/appointments/"
    + expectedAppointmentNumber.toString());
    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
            var responseAppointmentNumber = responsePayload.appointmentNumber;
            string responseDoctorName = responsePayload.doctor.name.toString();
            string responseAppoinmentDate = responsePayload.appointmentDate.toString();

            test:assertEquals(responseAppointmentNumber, expectedAppointmentNumber, 
                                                            msg = "Appointment number is not as expected!");
            test:assertEquals(responseDoctorName, expectedDoctorName, 
                                                            msg = "Doctor's name is not as expected!");
            test:assertEquals(responseAppoinmentDate, expectedAppointmentDate, 
                                                            msg = "Appointment date is not as expected!");
        } else {
            test:assertFail(msg = "Test Failed! Invalid Payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testGetAppointmentClemencyDataProvider() returns json[][] {
    return 
    [
    // TC005 - Verify if appoinment details can be retrieved successfully by providing a valid appointment number.
        [
            {
                "appointmentNumber": 1,
                "doctorName": "anne clement",
                "appointmentDate": "2019-07-02"
            }
        ]
    ];
}

# Description: This test scenario verifies if it throws an error message when an invalid appointment ID is 
# going to be retrieved.
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testGetAppointmentClemencyNegativeDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testGetAppointmentClemencyNegative(json dataset) {
    var expectedAppointmentNumber = dataset.appointmentNumber;
    var expectedSeerorMessage = dataset.expectedErrorMessage;

    http:Response | error response = clientEPclemency->get("/appointments/"
    + expectedAppointmentNumber.toString());
    if (response is http:Response) {
        string | error responsePayload = response.getTextPayload();
        test:assertEquals(responsePayload, expectedSeerorMessage, msg = "Error message is not as expected");
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testGetAppointmentClemencyNegativeDataProvider() returns json[][] {
    return 
    [
    // TC006 - Verify if an error occurs by providing an invalid appointment number.
        [
            {
                "appointmentNumber": 200,
                "expectedErrorMessage": "Invalid appointment number."
            }
        ]
    ];
}

# Description: This test scenario verifies if channel fee for a particular appoitment can be retreived. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testCheckChannellingFeeDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testCheckChannellingFee(json dataset) {
    string expectedPatientName = dataset.patientName.toString();
    string expectedDoctorname = dataset.doctorName.toString();
    string expectedFee = dataset.actualFee.toString();
    string appointmentNumber = dataset.appointmentNumber.toString();

    http:Response | error response = clientEPclemency->get("/appointments/" + appointmentNumber + "/fee");
    if (response is http:Response) {
        json | error responsePaylaod = response.getJsonPayload();
        if (responsePaylaod is json) {
            test:assertEquals(responsePaylaod.patientName, expectedPatientName, 
                                                    msg = "Assertion Failed!, Patient name is not as expected");
            test:assertEquals(responsePaylaod.doctorName, expectedDoctorname, 
                                                    msg = "Assertion Failed!, Doctor name is not as expected");
            test:assertEquals(responsePaylaod.actualFee, expectedFee, 
                                                    msg = "Assertion Failed!, Actual fee is not as expected");
        } else {
            test:assertFail(msg = "Invalid Payload. Test Failed!");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testCheckChannellingFeeDataProvider() returns json[][] {
    return 
    [
    // TC007 - Verify if the channel fee can be retrieved by providing a valid appoitment number.
        [
            {
                "appointmentNumber": 1,
                "patientName": "Leonardo Duke",
                "doctorName": "anne clement",
                "actualFee": "12000.0"
            }
        ]
    ];
}

# Description: This test scenario verifies if it throws an error message when it is going to check the fee of an 
# invalid appointment ID. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testCheckChannellingFeeNegativeDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testCheckChannellingFeeNegative(json dataset) {
    string appointmentNumber = dataset.appointmentNumber.toString();
    http:Response | error response = clientEPclemency->get("/appointments/" + appointmentNumber + "/fee");
    string expectedResponseText = dataset.errorMessage.toString();

    if (response is http:Response) {
        string | error responsePayload = response.getTextPayload();
        test:assertEquals(responsePayload, expectedResponseText, msg = "Error message is not as expected.");
    } else {
        test:assertFail(msg = "Error sending request!");
    }
}

function testCheckChannellingFeeNegativeDataProvider() returns json[][] {
    return 
    [
    // TC008 - Verify if the error message returns when an invalid appointment number is provided when it
    // is going to check the channelling fee.
        [
            {
                "appointmentNumber": 200,
                "errorMessage": "Error. Could not Find the Requested appointment ID."
            }
        ]
    ];
}

# Description: This test scenario verifies if Patient record can be updated. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testUpdatePatientRecordDataProvider",
    dependsOn: ["testReserveAppointment"]
}
function testUpdatePatientRecord(json dataset, json resultset) {
    http:Request request = new;
    request.setPayload(dataset);

    http:Response | error response = clientEPclemency->post("/patient/updaterecord", request);
    string expectedText = resultset.expectedText.toString();

    var expectedStatusCode = resultset.statusCode;

    if (response is http:Response) {
        string | error responsePayload = response.getTextPayload();
        test:assertEquals(response.statusCode, expectedStatusCode, 
                                                    msg = "Assertion Failed!, Status code mismatch");
        test:assertEquals(responsePayload, expectedText, 
                                                    msg = "Assertion Failed!, Record update is not success");
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testUpdatePatientRecordDataProvider() returns json[][] {
    return 
    [
    // TC009 - Verify patient's records can be updated.
        [
            {
                "ssn": "111-23-505",
                "symptoms": ["fever", "cough", "red scars", "nausea"],
                "treatments": ["paracetomol", "rest", "Cetirizine"]
            },
            {
                "statusCode": 200,
                "expectedText": "Record Update Success."
            }
        ]
    ];
}

# Description: This test scenario verifies if Patient's record can be retrieved successfully. 
# + dataset - dataset Parameter Description
@test:Config
{
    dataProvider: "testGetPatientRecordDataProvider",
    dependsOn: ["testUpdatePatientRecord"]
}
function testGetPatientRecord(json dataset) {
    string patientSsn = dataset.ssn.toString();
    http:Response | error response = clientEPclemency->get("/patient/" + patientSsn + "/getrecord");

    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if (responsePayload is json) {     
            test:assertEquals(response.statusCode, 200, msg = "The status code is not as expected");
        } else {
            test:assertFail(msg = "Test Failed! Invalid Payload");
        }
    } else {
        test:assertFail(msg = "Error sending the request");
    }
}

function testGetPatientRecordDataProvider() returns json[][] {
    return 
    [
    // TC010 - Verify if Patient record can be retrived
        [
            {
                "ssn": "111-23-505"
            }
        ]
    ];
}

# Description: This test scenario verifies if patient is eligible to get a discount. 
# + dataset - dataset Parameter Description
@test:Config {
    dataProvider: "testIsEligibleForDiscountDataProvider",
    dependsOn: ["testUpdatePatientRecord"]
}
function testIsEligibleForDiscount(json dataset) {
    string expectedAppointmentNumber = dataset.appointmentNumber.toString();
    var expectedEligilibity = dataset.eligibility;
    http:Response | error response = clientEPclemency->get("/patient/appointment/"
    + expectedAppointmentNumber + "/discount");
    if (response is http:Response) {
        json | error responsePayload = response.getJsonPayload();
        if (responsePayload is json) {
            test:assertEquals(responsePayload, expectedEligilibity, 
                                        msg = "Assertion Failed for appoinmentID: "+expectedAppointmentNumber);
        } else {
            test:assertFail(msg = "Invalid Payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

function testIsEligibleForDiscountDataProvider() returns json[][] {
    return 
    [
    // TC011 - Verify if patient who are below 55 and above 12 is not eligible for a discount.
        [
            {
                "eligibility": false,
                "appointmentNumber": 1
            }
        ],
        // TC012 - Verify if patient above 55 is eligible for a discount.
        [
            {
                "eligibility": true,
                "appointmentNumber": 2
            }
        ],
        // TC013 - Verify if patient below 12 is eligible for a discount.
        [
            {
                "eligibility": true,
                "appointmentNumber": 3
            }
        ]
    ];
}
