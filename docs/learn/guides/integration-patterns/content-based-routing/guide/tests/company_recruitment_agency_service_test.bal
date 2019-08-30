import ballerina/http;
import ballerina/io;
import ballerina/test;
import ballerina/log;
import ballerina/mime;

boolean serviceStarted = false;



function startService() {
    serviceStarted = test:startServices("company_recruitment_agency_service");

    serviceStarted = test:startServices("company_data_service");

}


@test:Config {
    before: "startService",
    after: "stopService"
}


function Company_Recruitments_Agency() {

// Invoking the main function
http:Client httpEndpoint = new("http://localhost:9091");

// Chck whether the server is started
test:assertTrue(serviceStarted, msg = "Unable to start the service");

json payload =  { "Name": "John and Brothers (pvt) Ltd" };
json payload2 = { "Name": "ABC Company" };
json payload3 = { "Name": "Smart Automobile" };


    json response1 = {

        "Name": "John and Brothers (pvt) Ltd",
        "Total_number_of_Vacancies": 12,
        "Available_job_roles" : "Senior Software Engineer = 3 ,Marketing Executives = 5 Management Trainees = 4",
        "CV_Closing_Date": "17/06/2018" ,
        "ContactNo": 1123456 ,
        "Email_Address": "careersjohn@jbrothers.com"
    };

    json response2 = {


        "Name":"ABC Company",
        "Total_number_of_Vacancies": 10,
        "Available_job_roles" : "Senior Finance Manager = 2 ,Marketing Executives = 6 HR Manager = 2",
        "CV_Closing_Date": "20/07/2018" ,
        "ContactNo": 112774 ,
        "Email_Address": "careers@abc.com"
    };

    json response3 = {


        "Name":"Smart Automobile",
        "Total_number_of_Vacancies": 11,
        "Available_job_roles" : "Senior Finance Manager = 2 ,Marketing Executives = 6 HR Manager = 3",
        "CV_Closing_Date": "20/07/2018" ,
        "ContactNo": 112774 ,
        "Email_Address": "careers@smart.com"

    };

    http:Request req = new;
    req.setJsonPayload(payload);
    // Send a GET request to the specified endpoint
    var response = httpEndpoint->post("/checkVacancies/company", req);
    if (response is http:Response) {
        var jsonRes = response.getJsonPayload();
        test:assertEquals(jsonRes, response1);
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }

    http:Request req2 = new;
    req2.setJsonPayload(payload2);
    response = httpEndpoint->post("/checkVacancies/company ",  req2);
    if (response is http:Response) {
        var jsonRes = response.getJsonPayload();
        test:assertEquals(jsonRes, response2);
    } else {
        test:assertFail(msg = "Failed to call the endpoint:");
    }

    http:Request req3 = new;
    req3.setJsonPayload(payload3);
    // Send a GET request to the specified endpoint
    response = httpEndpoint->post("/checkVacancies/company ", req3);

    if (response is http:Response) {
        var jsonRes = response.getJsonPayload();
        test:assertEquals(jsonRes, response3);
    }
    if (response is error) {
        test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function stopService() {
    test:stopServices("company_recruitment_agency_service");
    test:stopServices("company_data_service");
}

