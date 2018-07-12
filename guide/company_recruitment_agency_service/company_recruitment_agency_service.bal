import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/io;

//Deploying on kubernetes

//import ballerinax/kubernetes;

//@kubernetes:Ingress{
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-company_recruitment_agency_service",
//    path:"/"
//}
//
//@kubernetes:Service{
//    serviceType:"NodePort",
//    name:"ballerina-guides-company_recruitment_agency_service"
//}
//
//@kubernetes:Deployment{
//    image:"ballerina.guides.io/company_recruitment_agency_service:v1.0",
//    name:"ballerina-guides-company_recruitment_agency_service"
//}

//Deploying on docker

//import ballerinax/docker;

//@docker:Config{
//    registry:"ballerina.guides.io",
//    name:"company_recruitment_agency_service",
//    tag:"v1.0"
//}
//
//@docker:Expose {}
//

endpoint http:Listener comEP{
    port: 9091
};

//Client endpoint to communicate with company recruitment service
endpoint http:Client locationEP{
    url: "http://localhost:9090/companies"
};

//Service is invoked using basePath value "/checkVacancies"
@http:ServiceConfig{
    basePath: "/checkVacancies"
}

//"comapnyRecruitmentsAgency" route requests to relevant endpoints and get their responses.
service<http:Service> comapnyRecruitmentsAgency  bind comEP{

    // POST requests is directed to a specific company using,/checkVacancies/company.
    @http:ResourceConfig{
        methods: ["POST"],
        path: "/company"
    }

    comapnyRecruitmentsAgency(endpoint CompanyEP, http:Request req){
        //Get the JSON payload from the request message.
        var jsonMsg = req.getJsonPayload();
        
       //Parsing the JSON payload from the request
        match jsonMsg{
            json msg =>{
                //Get the string value relevant to the key `name`.
                string nameString;

                nameString = check <string>msg["Name"];

                //The http response can be either error|empty|clientResponse
                (http:Response|error|()) clientResponse;

                if (nameString == "John and Brothers (pvt) Ltd"){
                    //Routes the payload to the relevant service.
                    clientResponse =
                    locationEP->get("/John-and-Brothers-(pvt)-Ltd");

                }else if(nameString == "ABC Company"){
                    clientResponse =
                    locationEP->get("/ABC-Company");

                }else if(nameString == "Smart Automobile"){
                    clientResponse =
                    locationEP->get("/Smart-Automobile");

                }else {

                    clientResponse = log:printError("Company Not Found!");

                }

                //Use respond() to send the client response back to the caller.
                //when the request was successful, response is returned.
                //sends back the clientResponse to the caller if no any error is found.
                match clientResponse {
                    http:Response respone =>{
                        CompanyEP->respond(respone) but { error e =>
                        log:printError("Error sending response", err = e) };
                    }
                    error conError =>{
                        error err = {};
                        http:Response res = new;
                        res.statusCode = 500;
                        res.setPayload(err.message);
                        CompanyEP->respond(res) but { error e =>
                        log:printError("Error sending response", err = e) };
                    }
                    () => {}
                }
            }

            error err =>{
            //500 error response is constructed and sent back to the client.
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.message);
                CompanyEP->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}
