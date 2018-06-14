import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;



//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"passthrough",
//    path:"/"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"LKSubOffice"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"UKSubOffice"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"USHeadOffice"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/passthrough:v1.0",
//    name: "ballerina-guides-passt-hrough-messaging"
//}

//@docker:Expose {}
endpoint http:Listener LKSubOfficeEP {
    port:9090
};
//@docker:Expose {}
endpoint http:Listener UKSubOfficeEP {
    port:9091
};
//@docker:Expose {}
endpoint http:Listener USHeadOfficeEP {
    port:9092
};


//Define end-point for the sub offices as head office link
endpoint http:Client clientEP {
    url: "http://localhost:9092/USHeadOffice"
};


//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"passthrough",
//    tag:"v1.0"
//}


service<http:Service> LKSubOffice bind LKSubOfficeEP {
    // This service implement as a passthrough servise. So it allows all HTTP methods. So methods are not specified.
    @http:ResourceConfig {
        path: "/"
    }

    passthrough(endpoint caller, http:Request req) {
        // set log message as "the request will be directed to another service" in pass-through method.
        log:printInfo("You will be redirected to US head office from LK sub office  .......");
        //'Forward()' used to call the backend endpoint created above as pass-through method. In forward function,
        //it used the same HTTP method, which used to invoke the primary service.
        // The `forward()` function returns the response from the backend if there are no errors.
        var clientResponse = clientEP->forward("/", req);
        // Inorder to detect the errors in return output of the 'forward()' , it used 'match' to catch those kind of errors
        match clientResponse {
            // Returned response will directed to the outbound endpoint.
            http:Response res => {
                caller->respond(res)
                // If response contains errors, give the error message
                but { error e =>
                log:printError("Error sending response", err = e) };
            }
            // If there was an error, the 500 error response is constructed and sent back to the client.
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                caller->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}


// This service is also implemented as above service to undertand the scenario
service<http:Service> UKSubOffice bind UKSubOfficeEP {
    @http:ResourceConfig {
        path: "/"
    }
    passthrough(endpoint caller, http:Request req) {
        log:printInfo("You will be redirected to US head office from UK sub office  .......");
        var clientResponse = clientEP->forward("/", req);
        match clientResponse {
            http:Response res => {
                caller->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                caller->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}


//Sample Head office servise service.
service<http:Service> USHeadOffice bind USHeadOfficeEP {
    //The helloResource only accepts requests made using the specified HTTP methods.
    @http:ResourceConfig {
        methods: ["POST", "GET"],
        path: "/"
    }
    helloResource(endpoint caller, http:Request req) {
        //Set log to view the status to know that the passthrough was successfull.
        log:printInfo("Now You are connected to US head office  .......");
        // Make the response for the request
        http:Response res = new;
        res.setPayload("Welcome to WSO2 US head office!");
        // Pass the response to the caller
        caller->respond(res)
        // Cath the errors occured while passing the response
        but { error e =>
        log:printError("Error sending response", err = e) };
    }
}
