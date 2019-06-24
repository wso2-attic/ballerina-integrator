import ballerina/test;
import ballerina/http;
import ballerina/io;
import wso2/healthcare;

http:Client healthCareEP = new("http://localhost:9092/healthcare");

# Description: This test scenario verifies new docotr can be added to a hospital. 
# TC001 - Verify if a doctor can be added to Grand oak community hospital under the category surgery.
# TC002 - Verify if an existing doctor cannot be added. 
# TC003 - Verify if a doctor can be added under a new category.
#


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
        } else{
            test:assertFail(msg = "Error sending request");
        }

}

// This function passes data to testResourceAddAppoinment function for test cases.
function testAddDoctorResponseDataProvider() returns json[][] {
    return [
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


