import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//Deploying on Docker

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "company_data_service.bal",
//    tag: "v1.0"
//}
//
//@docker:Expose {}

//Deploying on Kubernetes

//
//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-company_data_service",
//    path: "/"
//}
//
//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-company_data_service"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/company_data_service:v1.0",
//    name: "ballerina-guides-company_data_service"
//}
listener http:Listener httpListener = new http:Listener(9090);

// Company data management is done using an in memory map.
map<json> companyDataMap = {};

// RESTful service.
@http:ServiceConfig { basePath: "/companies" }
service orderMgt on httpListener {
    // Resource that handles the HTTP GET requests that are directed to data of a specific
    // company using path '/John-and-Brothers-(pvt)-Ltd'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/John-and-Brothers-(pvt)-Ltd"
    }
    resource function findJohnAndBrothersPvtLtd(http:Caller caller, http:Request req) {
        json? payload = {
            Name: "John and Brothers (pvt) Ltd",
            Total_number_of_Vacancies: 12,
            Available_job_roles: "Senior Software Engineer = 3 ,Marketing Executives = 5 Management Trainees = 4",
            CV_Closing_Date: "17/06/2018",
            ContactNo: 1123456,
            Email_Address: "careersjohn@jbrothers.com"
        };

        http:Response response = new;
        if (payload == null) {
            payload = "Data : 'John-and-Brothers-(pvt)-Ltd' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the caller.
        var result = caller->respond(response);
        handleErrorWhenResponding(result);
    }

    // Resource that handles the HTTP GET requests that are directed to data
    // of a specific company using path '/ABC-Company'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/ABC-Company"
    }
    resource function findAbcCompany(http:Caller caller, http:Request req) {
        json? payload = {
            Name: "ABC Company",
            Total_number_of_Vacancies: 10,
            Available_job_roles: "Senior Finance Manager = 2 ,Marketing Executives = 6 HR Manager = 2",
            CV_Closing_Date: "20/07/2018",
            ContactNo: 112774,
            Email_Address: "careers@abc.com"
        };

        http:Response response = new;
        if (payload == null) {
            payload = "Data : 'ABC-Company' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        var result = caller->respond(response);
        handleErrorWhenResponding(result);
    }

    // Resource that handles the HTTP GET requests that are directed to a specific
    // company data of company using path '/Smart-Automobile'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/Smart-Automobile"
    }
    resource function findSmartAutomobile(http:Caller caller, http:Request req) {
        json? payload = {
            Name: "Smart Automobile",
            Total_number_of_Vacancies: 11,
            Available_job_roles: "Senior Finance Manager = 2 ,Marketing Executives = 6 HR Manager = 3",
            CV_Closing_Date: "20/07/2018",
            ContactNo: 112774,
            Email_Address: "careers@smart.com"
        };

        http:Response response = new;
        if (payload == null) {
            payload = "Data : 'Smart-Automobile' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        var result = caller->respond(response);
        handleErrorWhenResponding(result);
    }
}

function handleErrorWhenResponding(error? result) {
    if (result is error) {
        log:printError("Error when responding", err = result);
    }
}
