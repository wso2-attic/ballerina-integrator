import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/io;

//Deploying on kubernetes

//import ballerina/http;
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

//import ballerina/http;
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
    port: 9090
};

//Client endpoint to communicate with company recruitment service
endpoint http:Client locationEP{
    url: "http://www.mocky.io"
};

//Service is invoked using basePath value "/checkVacancies"
@http:ServiceConfig{
    basePath: "/checkVacancies"
}

//"comapnyRecruitmentsAgency" route requests to relevant endpoints and get their responses.
service<http:Service> comapnyRecruitmentsAgency  bind comEP{

    //Resource that handles the POST requests is directed to a specific company using,/checkVacancies/company.
    @http:ResourceConfig{
        methods: ["POST"],
        path: "/company"
    }

    comapnyRecruitmentsAgency(endpoint CompanyEP, http:Request req){
        //Get the JSON payload from the request message.
        var jsonMsg = req.getJsonPayload();
       
        match jsonMsg{
            //Try parsing the JSON payload from the request
            json msg =>{
                //Get the string value relevant to the key `name`.
                string nameString;

                nameString = check <string>msg["Name"];

                //The http response can be either error|empty|clientResponse
                (http:Response|error|()) clientResponse;

                if (nameString == "John and Brothers (pvt) Ltd"){
                    //Routes the payload to the relevant service when the server accepts the enclosed entity.
                    clientResponse =
                    locationEP->post("/v2/5b22493f2e00009200e315ec");

                }else if(nameString == "ABC Company"){
                    clientResponse =
                    locationEP->post("/v2/5b2244db2e00007e00e315c5");

                }else{ 
                    clientResponse =
                    locationEP->post("/v2/5b22443d2e00007b00e315b9");
                }
                    
                //Use the native function 'respond' to send the client response back to the caller.
                match clientResponse {
                    //If the request was successful, an HTTP response is returned.
                    //respond()` sends back the inbound clientResponse to the caller if no any error is found.
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
                // If there was an error, the 500 error response is constructed and sent back to the client.
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                CompanyEP->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}
