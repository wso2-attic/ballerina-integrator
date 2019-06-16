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
import ballerina/time;

http:Client healthCareEP = new("http://localhost:9090/healthcare");

# Description: This test scenario verifies new docotr can be added to a hospital. 
# TC001 - Verify if a doctor can be added to Grand oak community hospital under the category surgery.
#
# + dataset - dataset Parameter Description
@test:Config 
{
    dataProvider: "testAddDoctorResponseDataProvider"
}

function testAddDoctor(json dataset)
{
    http:Request request = new;
    json payload = dataset; 
    request.setPayload(payload);

    var response = healthCareEP->post("/admin/newdoctor", request);

    if (response is http:Response)
    {
        var resPayload = response.getTextPayload();
        var expectedResponse = "New Doctor Added Successfully.";
        test:assertEquals(resPayload, expectedResponse,msg = "Response mismatch!");
        test:assertEquals(response.statusCode, 200,msg = "Status Code mismatch");  
    }else
    {
        test:assertFail(msg = "Test failed");
    }
} 

// This function passes data to testResourceAddAppoinment function for test cases.
function testAddDoctorResponseDataProvider() returns json[][]{
     return [
                [
                    {
	                    "name":"T D Uyanage",
	                    "hospital":"grand oak community hospital",
	                    "category":"surgery",
	                    "availability":"Weekends",
	                    "fee":2500.0
                    }
                ]
            ]; 
        }

# Description: This test scenario verifies if a doctor record can be retrived. 
# TC002 - Verify if added doctor record under TC001 can be retrived under category surgery.
# 
# + dataset - dataset Parameter Description
@test:Config 
{
    dataProvider: "testGetDoctorsDataProvider",
    dependsOn: ["testAddDoctor"]
}

function testGetDoctors(json dataset) 
{
    string inputCategory = dataset.category.toString();
    boolean includeDoctor = false;
    string doctor = dataset.doctor.toString();

    var response = healthCareEP->get("/"+inputCategory+"/");

    if (response is http:Response) 
    {
        var responsePayload = response.getJsonPayload(); 
        if(responsePayload is json)
        {
             if(responsePayload.toString().contains(doctor))
             {
                 includeDoctor = true;
                 test:assertEquals(includeDoctor, true, msg = "Assertion Failed!, Response does not contain the doctor "+doctor);
             }
             else
             {
                 test:assertFail(msg = "Test Failed!");
             }
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

// This function passes data to testResourceAddAppoinment function for test cases.
function testGetDoctorsDataProvider() returns json[][]
{
     return [
                [
                    {
	                    "category":"surgery",
                        "doctor": "T D Uyanage"
                    }
                ]
            ]; 
}

# Description: This test scenario verifies if it cab retreive te details of appointments.
# TC003 - verifi if appointment details can be retreived.
#
# + dataset - dataset Parameter Description 
# + resultset - resultset Parameter Description
@test:Config 
{
    dataProvider: "testGetAppointmentDataProvider",
    dependsOn: ["testReserveAppointment"]
}

function testGetAppointment(json dataset, json resultset)
{
    string inputAppointmentNumber = dataset.appointmentNumber.toString();
    var response = healthCareEP->get("/appointments/"+inputAppointmentNumber);

    if (response is http:Response) 
    {
        var responsePayload = response.getJsonPayload(); 
        if(responsePayload is json)
        {
            test:assertEquals(responsePayload, resultset, msg = "Assertion Failed!, json payload mismatch");
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

function testGetAppointmentDataProvider() returns json[][]
{
     return [
                [
                    {
	                    "appointmentNumber":1
                    },
                    {
                        "appointmentNumber":1, 
                        "doctor":
                            {
                                "name":"anne clement", 
                                "hospital":"clemency medical center", 
                                "category":"surgery", 
                                "availability":"8.00 a.m - 10.00 a.m", 
                                "fee":12000.0
                            }, 
                        "patient":
                        {
                            "name":"Leonardo Duke", 
                            "dob":"1988-03-19", 
                            "ssn":"111-23-505", 
                            "address":"NY", 
                            "phone":"8070586755", 
                            "email":"jduke@gmail.com"
                        }, 
                        "fee":12000.0, 
                        "confirmed":false, 
                        "appointmentDate":"2019-07-02"
                    }
                ]
            ]; 
}

# Description: This test scenario verifies the validity of the appointment date.
# TC003 - verifi if the provided appointment date is valid.
#
# + dataset - dataset Parameter Description 
# + resultset - resultset Parameter Description
@test:Config 
{
    dataProvider: "testGetAppointmentValidityTimeDataProvider",
    dependsOn: ["testReserveAppointment"]
}

function testGetAppointmentValidityTime(json dataset)
{
    string inputAppointmentNumber = dataset.appointmentNumber.toString();
    // getting the expected validity days
    var response = healthCareEP->get("/appointments/"+inputAppointmentNumber);
    int expectedValidityDays = 0;
    if (response is http:Response) 
    {
        var responsePayload = response.getJsonPayload();
        if(responsePayload is json)
        {
            string appointmentDateFromPayload = responsePayload.appointmentDate.toString();
            var date = time:parse(appointmentDateFromPayload, "yyyy-MM-dd");
             if (date is time:Time) 
             {
                time:Time today = time:currentTime();
                // Get no of days remaining for the appointment.
                expectedValidityDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
            }
            else
            {
                test:assertFail(msg = "Test Failed for invalid date");
            }       
        }
        else
        {
             test:assertFail(msg = "Test Failed in getting the json payload of appointment date!");
        }  
    }
    else
    {
        test:assertFail(msg = "Error sending request to get appointment details");
    }
    
    // getting the actual validity days
    var responseValidity = healthCareEP->get("/appointments/validity/"+inputAppointmentNumber);
    if (responseValidity is http:Response) 
    {
        var responsePayloadActual = responseValidity.getJsonPayload();
        if(responsePayloadActual is json)
        {
            test:assertEquals(responsePayloadActual, expectedValidityDays, msg = "Assertion Failed!");
        }
        else
        {
             test:assertFail(msg = "Test Failed in getting the json payload for actual validity days");
        }
    }
    else
    {
         test:assertFail(msg = "Error sending request in getting actual validity days");
    }
}

function testGetAppointmentValidityTimeDataProvider() returns json[][]
{
     return [
                [
                    {
	                    "appointmentNumber":1
                    }
                ]
            ]; 
}

# Description: This test scenario verifies if the appointments can be removed.
# TC004 - verify if appointments can be deleted.
#
# + dataset - dataset Parameter Description 
# + resultset - resultset Parameter Description
@test:Config 
{
    dataProvider: "testRemoveAppointmentDataProvider",
    dependsOn: ["testIsEligibleForDiscountGrandoaks"]
}

function testRemoveAppointment(json dataset)
{
    string inputAppointmentNumber = dataset.appointmentNumber.toString();
    var response = healthCareEP->delete("/appointments/"+inputAppointmentNumber, "Remove Appointment");
    if (response is http:Response) 
    {
        var actualResponse = response.getTextPayload();
        var expectedResponse = dataset.response;
        test:assertEquals(actualResponse, expectedResponse, msg = "Assertion Failed!");
    }
    else
    {
        test:assertFail(msg = "Error sending request!");
    }   
}

function testRemoveAppointmentDataProvider() returns json[][]
{
     return [
                [
                    {
	                    "appointmentNumber":6,
                        "response":"Appointment is successfully removed."
                    }
                ]
            ]; 
}

# Description: This test scenario verifies payments can be settled successfully. 
# TC005 - verify if payment can be setteled for a given appointment.
#
# + dataset - dataset Parameter Description
@test:Config 
{
    dataProvider: "testSettlePaymentDataProvider",
    dependsOn: ["testIsEligibleForDiscount"]
}

function testSettlePayment(json dataset)
{
    http:Request request = new;
    json payload = dataset; 
    request.setPayload(payload);

    var response = healthCareEP->post("/payments", request);
    if (response is http:Response)
    {
        var responsePayload = response.getTextPayload();
        if(responsePayload is string)
        {
            boolean isSuccessfullySettled = false;
            if(responsePayload.contains("Settled payment successfully with payment ID"))
            {
                isSuccessfullySettled = true;
                test:assertEquals(isSuccessfullySettled, true, msg = "Assertion Failed!");
            }
            else
            {
                test:assertFail(msg = "Test Failed!");
            }
        }
        else
        {
            test:assertFail(msg = "Test Failed!");
        }
    }
    else
    {
        test:assertFail(msg = "Error sending request!");
    }
}

function testSettlePaymentDataProvider() returns json[][]
{
     return [
                [
                    {
                        "appointmentNumber":1,
                        "doctor":
                        {
                            "category": "surgery",
                            "name": "anne clement",
                            "hospital": "clemency medical center",
                            "availability": "10am - 6pm",
                            "fee": 10000.00
                        },
                        "patient":
                        {  
                            "name":"Kate Winslet",
                            "dob":"1970-03-19",
                            "ssn":"234-987-175",
                            "address":"Canada",
                            "phone":"32456789765",
                            "email":"kwinslet@gmail.com"
                        },
                        "fee":1800.0,
                        "confirmed":true,
                        "cardNumber":"3456812345"
                    }
                ]
            ]; 
}
          
  