import ballerina/http;

endpoint http:Listener listener {
    port: 9090
};

// Company Data management is done using an in memory map.
map<json> companyDataMap;


// RESTful service.
@http:ServiceConfig { basePath: "/companies" }
service<http:Service> orderMgt bind listener {
    // Resource that handles the HTTP GET requests that are directed to a specific
    // Company data of company using path '/John-and-Brothers-(pvt)-Ltd'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/John-and-Brothers-(pvt)-Ltd"
    }
    findJohnAndBrothersPvtLtd(endpoint client, http:Request req) {
        json? payload = {
            Name: "John and Brothers (pvt) Ltd",
            Total_number_of_Vacancies: 12,
            Available_job_roles : "Senior Software Engineer = 3 ,Marketing Executives =5 Management Trainees=4",
            CV_Closing_Date: "17/06/2018" ,
            ContactNo: 01123456 ,
            Email_Address: "careersjohn@jbrothers.com"
        };

        http:Response response;
        if (payload == null) {
            payload = "Data : 'John-and-Brothers-(pvt)-Ltd' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);
    }

    // Resource that handles the HTTP GET requests that are directed to a specific
    // Company data of company using path '/ABC-Company'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/ABC-Company"
    }
    findAbcCompany(endpoint client, http:Request req) {
        json? payload = {
            Name:"ABC Company",
            Total_number_of_Vacancies: 10,
            Available_job_roles : "Senior Finance Manager = 2 ,Marketing Executives =6 HR Manager=2",
            CV_Closing_Date: "20/07/2018" ,
            ContactNo: 0112774 ,
            Email_Address: "careers@abc.com"
        };

        http:Response response;
        if (payload == null) {
            payload = "Data : 'ABC-Company' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);
    }

    // Resource that handles the HTTP GET requests that are directed to a specific
    // Company data of company using path '/Smart-Automobile'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/Smart-Automobile"
    }
    findSmartAutomobile(endpoint client, http:Request req) {
        json? payload = {
            Name:"Smart Automobile",
            Total_number_of_Vacancies: 11,
            Available_job_roles : "Senior Finance Manager = 2 ,Marketing Executives =6 HR Manager=3",
            CV_Closing_Date: "20/07/2018" ,
            ContactNo: 0112774 ,
            Email_Address: "careers@smart.com"
        };

        http:Response response;
        if (payload == null) {
            payload = "Data : 'Smart-Automobile' cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);
    }
}




