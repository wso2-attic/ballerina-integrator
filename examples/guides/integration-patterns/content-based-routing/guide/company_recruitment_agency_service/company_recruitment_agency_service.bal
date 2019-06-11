import ballerina/http;
import ballerina/log;


//Deploying on Docker

//import ballerinax/docker;
//
//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "company_recruitment_agency_service",
//    tag: "v1.0"
//}
//
//@docker:Expose {}

//Deploying on Kubernetes

//import ballerinax/kubernetes;
//
//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-company_recruitment_agency_service",
//    path: "/"
//}
//
//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-company_recruitment_agency_service"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/company_recruitment_agency_service:v1.0",
//    name: "ballerina-guides-company_recruitment_agency_service"
//}
listener http:Listener comEP = new http:Listener(9091);

//Client endpoint to communicate with company recruitment service
http:Client locationEP = new("http://localhost:9090/companies");

//Service is invoked using basePath value "/checkVacancies"
@http:ServiceConfig {
    basePath: "/checkVacancies"
}
//"comapnyRecruitmentsAgency" routes requests to relevant endpoints and gets their responses.
service comapnyRecruitmentsAgency on comEP {

    // POST requests is directed to a specific company using, /checkVacancies/company.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/company"
    }
    resource function comapnyRecruitmentsAgency(http:Caller CompanyEP, http:Request req) {
        //Get the JSON payload from the request message.
        var jsonMsg = req.getJsonPayload();

        //Parsing the JSON payload from the request
        if (jsonMsg is json) {
            //Get the string value relevant to the key `name`.
            string nameString;

            nameString = <string>jsonMsg["Name"];

            //The HTTP response can be either error|empty|clientResponse
            (http:Response|error|()) clientResponse;

            if (nameString == "John and Brothers (pvt) Ltd") {
                //Routes the payload to the relevant service.
                clientResponse =
                locationEP->get("/John-and-Brothers-(pvt)-Ltd");

            } else if (nameString == "ABC Company") {
                clientResponse =
                locationEP->get("/ABC-Company");

            } else if (nameString == "Smart Automobile") {
                clientResponse =
                locationEP->get("/Smart-Automobile");

            } else {
                clientResponse = log:printError("Company Not Found!");
            }

            //Use respond() to send the client response back to the caller.
            //When the request is successful, the response is returned.
            //Sends back the clientResponse to the caller if no error is found.
           if(clientResponse is http:Response) {
                var result = CompanyEP->respond(clientResponse);
                handleErrorWhenResponding(result);
           } else if (clientResponse is error) {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(<string>clientResponse.detail().message);
                var result = CompanyEP->respond(res);
                handleErrorWhenResponding(result);
           }
        } else {
            //500 error response is constructed and sent back to the client.
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(untaint <string>jsonMsg.detail().message);
            var result = CompanyEP->respond(res);
            handleErrorWhenResponding(result);
        }
    }
}

function handleErrorWhenResponding(error? result) {
    if (result is error) {
        log:printError("Error when responding", err = result);
    }
}
