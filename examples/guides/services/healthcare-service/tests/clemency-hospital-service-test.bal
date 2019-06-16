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
import ballerina/log;

http:Client clientEPclemency = new("http://localhost:9090/clemency/categories");

# Description: This test verifies if an appoinment can be reserved successfully. 
# TC001 - Verify if appoinement reservation can be done by providing all the valid inputs. 
# TC002 - Verify if appoinment reservation can be done by not providing non-mandatory feilds.
# TC003 - Verify if appoinment reservation can be done for an unavailable doctor in the hospital. 
#
# + dataset - dataset Parameter Description
@test:Config 
{
    dataProvider: "testReserveAppointmentDataProvider",
     dependsOn: ["testAddDoctor"]
}

function testReserveAppointment(json dataset, json expectedStrings) 
{
    // set the json payload
    http:Request request = new;
    json payload = dataset;
    request.setPayload(payload);

    // sending the post request to the endpoint
    var response = clientEPclemency->post("/surgery/reserve", request);

    if(response is http:Response)
    {
        string doctor= dataset.doctor.toString();
        var responseStatusCode = response.statusCode;
        var expectedStatusCode = expectedStrings.statusCode;
        var expectedResponseText = expectedStrings.responseMessage;

        if(doctor == "T Uyanage")
        {
            var responsePayload = response.getTextPayload();
            test:assertEquals(responsePayload, expectedResponseText, msg = "Assertion Failed for Doctor " +doctor);
            test:assertEquals(responseStatusCode, expectedStatusCode, msg = "Status code mismatch!");
        }
        else
        {
            var resonsePayload = response.getJsonPayload();
            var expectedIncludesAppoinmentNumber = expectedStrings.appoinmentNumber;
            var expectedIncludesDoctorAvailibility = expectedStrings.doctorAvailibility;
            var expectedIncludesDoctorFee = expectedStrings.doctorFee;

            if(resonsePayload is json)
            {
                boolean responseIncludesAppoinmentNumber = false;
                boolean responseIncludesDoctorAvailibility = false;
                boolean responseIncludesDoctorFee = false;

                // Verifying if response json payload includes appointmentNumber, availability and fee
                if(resonsePayload.toString().contains("appointmentNumber"))
                {
                    responseIncludesAppoinmentNumber = true;
                }
                if(resonsePayload.doctor.toString().contains("availability"))
                {
                    responseIncludesDoctorAvailibility = true;
                }
                if(resonsePayload.toString().contains("fee"))
                {
                    responseIncludesDoctorFee = true;
                }
                test:assertEquals(response.statusCode, expectedStatusCode, msg = "Status Code mismatch!");
                test:assertEquals(responseIncludesAppoinmentNumber, expectedIncludesAppoinmentNumber, msg = "Appoinment number is not as expected");
                test:assertEquals(responseIncludesDoctorAvailibility, expectedIncludesDoctorAvailibility, msg = "Doctor availability is not as expected");
                test:assertEquals(responseIncludesDoctorFee, expectedIncludesDoctorFee, msg = "Doctor fee is not as expected");  
            }
            else
            {
                test:assertFail(msg = "Test Failed!");
            }
        }
    }
    else
    {
        test:assertFail(msg = "Error sending request");
    }
}

function testReserveAppointmentDataProvider() returns json[][]
{
     return [
                [
                   {  
                        "patient":{  
                            "name":"Leonardo Duke",
                            "dob":"1988-03-19",
                            "ssn":"111-23-505",
                            "address":"NY",
                            "phone":"8070586755",
                            "email":"jduke@gmail.com"
                        },
                        "doctor":"anne clement",
                        "hospital":"clemency medical center",
                        "appointmentDate":"2019-07-02"
                    },
                    {
                        "statusCode":200,
                        "appoinmentNumber":true,
                        "doctorAvailibility":true,
                        "doctorFee":true
                    }
                 
                ],
                [
                   {  
                        "patient":{  
                            "name":"J Serasinghe",
                            "dob":"1951-03-19",
                            "ssn":"112-29-585",
                            "address":"California",
                            "phone":"8070521755",
                            "email":""
                        },
                        "doctor":"thomas kirk",
                        "hospital":"clemency medical center",
                        "appointmentDate":"2019-08-30"
                    },
                    {
                        "statusCode":200,
                        "appoinmentNumber":true,
                        "doctorAvailibility":true,
                        "doctorFee":true
                    } 
                ],
                [
                   {  
                        "patient":{  
                            "name":"D Serasinghe",
                            "dob":"1983-12-03",
                            "ssn":"777-29-585",
                            "address":"Colombo SL",
                            "phone":"5578521755",
                            "email":"dserasinghe@hotmail.com"
                        },
                        "doctor":"T Uyanage",
                        "hospital":"clemency medical center",
                        "appointmentDate":"2019-12-31"
                    },
                    {
                        "statusCode":400,
                        "responseMessage":"Doctor T Uyanage is not available in clemency medical center"
                    }
                ],
                [
                   {  
                        "patient":{  
                            "name":"Little John",
                            "dob":"2018-04-29",
                            "ssn":"",
                            "address":"California",
                            "phone":"",
                            "email":""
                        },
                        "doctor":"cailen cooper",
                        "hospital":"clemency medical center",
                        "appointmentDate":"2019-12-02"
                    },
                    {
                        "statusCode":200,
                        "appoinmentNumber":true,
                        "doctorAvailibility":true,
                        "doctorFee":true
                    } 
                ]
            ]; 
        }

# Description: This test scenario verifies if details of the reserved appoinment can be retrived. 
# TC004 - Verify if appoinment details can be retrieved successfully by providing a valid appointment number.
# TC005 - Verify if an error occurs by providing an invalid appointment number.  
#
# + dataset - dataset Parameter Description
@test:Config
{
    dataProvider: "testGetAppointmentClemencyDataProvider",
    dependsOn: ["testReserveAppointment"]
}


function testGetAppointmentClemency(json dataset)
{
    var expectedAppointmentNumber = dataset.appointmentNumber;
    var expectedDoctorName = dataset.doctorName;
    var expectedAppointmentDate = dataset.appointmentDate;

    var response = clientEPclemency->get("/appointments/"+expectedAppointmentNumber.toString());
    if(response is http:Response)
    {
        if(expectedAppointmentNumber == 20000000)
        {
            var responsePayload = response.getTextPayload();
            test:assertEquals(responsePayload, "Invalid appointment number.", msg = "Assertion Failed!");
        }
        else
        {
            var responsePayload = response.getJsonPayload();
            if(responsePayload is json)
            {
                var responseAppointmentNumber = responsePayload.appointmentNumber;
                var responseDoctorName = responsePayload.doctor.name;
                var responseAppoinmentDate = responsePayload.appointmentDate;

                test:assertEquals(responseAppointmentNumber, expectedAppointmentNumber, msg = "Appointment number is not as expected!");
                test:assertEquals(responseDoctorName, expectedDoctorName, msg = "Doctor's name is not as expected!");
                test:assertEquals(responseAppoinmentDate, expectedAppointmentDate, msg = "Appointment date is not as expected!");
            }
            else
            {
                test:assertFail(msg = "Test Failed!");
            }
        }
    }   
    else 
    {
        test:assertFail(msg = "Error sending request");
    }

}

function testGetAppointmentClemencyDataProvider() returns json[][]{
    return [
                [
                    {
                        "appointmentNumber":1,
                        "doctorName":"anne clement",
                        "appointmentDate":"2019-07-02"
                    }  
                ],
                [
                    {
                        "appointmentNumber":20000000
                    }  
                ]
            ]; 
        }

# Description: This test scenario verifies if channel fee for a particular appoitment can be retreived. 
# TC006 - Verify if the channel fee can be retrieved by providing a valid appoitment number. 
# TC007 - Verify if an error occurs by providing an invalid appointment number.  
# 
# + dataset - dataset Parameter Description
@test:Config{
    dataProvider: "testCheckChannellingFeeDataProvider",
    dependsOn: ["testReserveAppointment"]
}

function testCheckChannellingFee(json dataset)
{   
    var expectedPatientName = dataset.patientName;
    var expectedDoctorname = dataset.doctorName;
    var expectedFee = dataset.actualFee;
    var expectedResponseText = "Error. Could not Find the Requested appointment ID.";
    string appointmentNumber = dataset.appointmentNumber.toString();

    var response = clientEPclemency->get("/appointments/"+appointmentNumber+"/fee");  
     if(response is http:Response)
     {
        if(dataset.appointmentNumber == 20000000)
        {
            var responsePayload = response.getTextPayload();
            test:assertEquals(responsePayload, expectedResponseText, msg = "Assertion Failed!");
        }
        else
        {
            var responsePaylaod = response.getJsonPayload();
            if(responsePaylaod is json)
            {
                test:assertEquals(responsePaylaod.patientName, expectedPatientName, msg = "Assertion Failed!, Patient name is not as expected");
                test:assertEquals(responsePaylaod.doctorName, expectedDoctorname, msg = "Assertion Failed!, Doctor name is not as expected");
                test:assertEquals(responsePaylaod.actualFee, expectedFee, msg = "Assertion Failed!, Actual fee is not as expected");
            }
            else
            {
                test:assertFail(msg = "Test Failed!");
            }
        }
    }
    else
    {
        test:assertFail(msg = "Error sending request");
    }
}

function testCheckChannellingFeeDataProvider() returns json[][]{
    return [
                [
                    {
                        "appointmentNumber":1,
                        "patientName":"Leonardo Duke",
                        "doctorName":"anne clement",
                        "actualFee":"12000.0"
                    }  
                ],
                [
                    {
                        "appointmentNumber":20000000
                    }  
                ]
            ]; 
        }

# Description: This test scenario verifies if Patient record can be updated. 
# TC008 - Verify patient's records can be updated. 
#
# + dataset - dataset Parameter Description
@test:Config{
    dataProvider: "testUpdatePatientRecordDataProvider",
    dependsOn: ["testReserveAppointment"]
}

function testUpdatePatientRecord(json dataset){
    http:Request request = new;
    json payload = dataset;
    request.setPayload(payload);
    var response = clientEPclemency->post("/patient/updaterecord", request);

    if(response is http:Response){
        var responsePayload = response.getTextPayload();
        test:assertEquals(response.statusCode, 200, msg = "Assertion Failed!, Status code mismatch");
        test:assertEquals(responsePayload, "Record Update Success.", msg = "Assertion Failed!, Record update is not success");
    }else{
        test:assertFail(msg = "Error sending request");
    }
}

function testUpdatePatientRecordDataProvider() returns json[][]{
    return [
                [
                    {
	                    "ssn": "111-23-505",
	                    "symptoms": ["fever", "cough", "red scars", "nausea"],
	                    "treatments": ["paracetomol", "rest","Cetirizine"]
                    }  
                ]
            ]; 
        }


# Description: This test scenario verifies if Patient's record can be retrieved successfully. 
# TC009 - Verify if Patient record can be retrived
#
# + dataset - dataset Parameter Description
@test:Config
{
    dataProvider: "testGetPatientRecordDataProvider",
    dependsOn: ["testUpdatePatientRecord"]
}

function testGetPatientRecord(json dataset)
{
    var expectedPatientName = dataset.patientName;
    var expectedDob = dataset.dob;
    string expectedSsn = dataset.ssn.toString();
    boolean responseContainsSymptoms = false;
    boolean responseContainsTreatments = false;

    var response = clientEPclemency->get("/patient/"+expectedSsn+"/getrecord");

    if(response is http:Response)
    {
        var responsePayload = response.getJsonPayload();
        if(responsePayload is json)
        {
            if(responsePayload.toString().contains("symptoms"))
            {
                responseContainsSymptoms = true;
            }
            if(responsePayload.toString().contains("treatments"))
            {
                responseContainsTreatments = true;
            }
            test:assertEquals(responsePayload.patient.name, expectedPatientName, msg = "Assertion Failed!, Patient name is not as expected");
            test:assertEquals(responsePayload.patient.dob, expectedDob, msg = "Assertion Failed!, Patient dob is not as expected");
            test:assertEquals(responseContainsSymptoms, true, msg = "Assertion Failed!, Response does not contain symptoms");
            test:assertEquals(responseContainsTreatments, true, msg = "Assertion Failed!, Response does not contain treatments");
        }
        else
        {
            test:assertFail(msg = "Test Failed!");
        }
    }
    else
    {
        test:assertFail(msg = "Error sending request");
    }
}

function testGetPatientRecordDataProvider() returns json[][]{
    return [
                [
                    {
                        "patientName":"Leonardo Duke",
                        "dob":"1988-03-19",
                        "ssn":"111-23-505"
                    }  
                ]
            ]; 
        }


# Description: This test scenario verifies if patient is eligible to get a discount. 
# TC010 - Verify if patient who are below 55 and above 12 is not eligible for a discount.
# TC011 - Verify if patient above 55 is eligible for a discount. 
# TC012 - Verify if patient below 12 is eligible for a discount. 
#
# + dataset - dataset Parameter Description
@test:Config
{
    dataProvider: "testIsEligibleForDiscountDataProvider",
    dependsOn: ["testUpdatePatientRecord"]
}

function testIsEligibleForDiscount(json dataset)
{
    string expectedAppointmentNumber = dataset.appointmentNumber.toString();
    var expectedEligilibity = dataset.eligibility;
    var response = clientEPclemency->get("/patient/appointment/"+expectedAppointmentNumber+"/discount");
    if(response is http:Response)
    {
        var responsePayload = response.getJsonPayload();
        if(responsePayload is json)
        {
            test:assertEquals(responsePayload, expectedEligilibity, msg = "Assertion Failed for appoinmentID: "+expectedAppointmentNumber);
        }else
        {
            test:assertFail(msg = "Test Failed!");
        }
    }
    else
    {
        test:assertFail(msg = "Error sending request");
    }
}


function testIsEligibleForDiscountDataProvider() returns json[][]{
    return [
                [
                    {
                        "eligibility":false,
                        "appointmentNumber":1
                    }  
                ],
                [
                    {
                        "eligibility":true,
                        "appointmentNumber":2
                    }  
                ],
                [
                    {
                        "eligibility":true,
                        "appointmentNumber":3
                    }  
                ]
            ]; 
        }

# Description: This scenario verifies if new doctor can be added. 
# TC013 - Verify if new doctor can be added to the hospital. 
# TC014 - Verify if an already existing doctor cannot be added to the hospital. 
#
# + dataset - dataset Parameter Description 
# + expectedStrings - expectedStrings Parameter Description
@test:Config
{
    dataProvider: "testAddNewDoctorDataProvider",
    dependsOn: ["testIsEligibleForDiscount"]
}

function testAddNewDoctor(json dataset,json expectedStrings)
{
    var expectedMessage = expectedStrings.assertText;
    var expectedStatusCode = expectedStrings.statusCode;

    //set request json payload
    http:Request request = new;
    json payload = dataset;
    request.setPayload(payload);
    var response = clientEPclemency->post("/admin/doctor/newdoctor", request);

    if(response is http:Response)
    {
        var responsePayload = response.getTextPayload();
        test:assertEquals(response.statusCode, expectedStatusCode, msg = "Assertion Failed! Status code mismatch");
        test:assertEquals(responsePayload, expectedMessage, msg = "Assertion Failed for the payload text!");
    }
    else
    {
        test:assertFail(msg = "Error sending request.");
    }
}

function testAddNewDoctorDataProvider() returns json[][]{
    return [
                [
                    {
                        "category": "Veterinary Surgeon",
                        "name": "S N Silva",
                        "hospital": "Lanka Hospitals",
                        "availability": "10am - 6pm",
                        "fee": 10000.00
                    },
                    {
                        "assertText":"New Doctor Added Successfully.",
                        "statusCode":200
                    }
                ], 
                [
                    {
                        "category": "Veterinary Surgeon",
                        "name": "S N Silva",
                        "hospital": "Nawaloka Hospitals",
                        "availability": "7pm - 10pm",
                        "fee": 10000.00
                    },
                    {
                        "assertText":"Doctor Already Exists in the system.",
                        "statusCode":400
                    }
                ]
            ]; 
        }

