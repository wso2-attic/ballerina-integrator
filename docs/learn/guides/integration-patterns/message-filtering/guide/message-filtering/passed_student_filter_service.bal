import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;
//
//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "passed_student_filter_service",
//    tag: "v1.0"
//}
//
//@docker:Expose {}

//
//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-passed_student_filter_service",
//    path: "/"
//}
//
//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-passed_student_filter_service"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/passed_student_filter_service:v1.0",
//    name: "ballerina-guides-passed_student_filter_service"
//}

listener http:Listener filterServiceEP = new(9090);

http:Client stdInfoEP = new("http://www.mocky.io");

// REST service to select the passed student from an exam
service filterService on filterServiceEP {

    // Resource that handle HTTP POST request with JSON payload
    // Response with JSON payload
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function filterMarks(http:Caller caller, http:Request request) {

        // Declare boolean flag to set Qualified or Not
        boolean isQualified = false;

        // Set Original payload to a new request object
        http:Request req = new;

        // Get the JSON payload from the request
        var reqPayload = request.getJsonPayload();
        if (reqPayload is json) {
            // Get the information of the subjects
            string stdName = <string>reqPayload.name;
            json[] subjects = <json[]>reqPayload.subjects;

            // Iterating subject array
            foreach var subj in subjects {
                int mark = <int>subj.marks;
                // Check the student exceed the pass mark value
                if (mark >= 60) {
                    isQualified = true;
                } else {
                    isQualified = false;
                }
            }
            req.setJsonPayload(untaint reqPayload);
        } else {
            http:Response errResp = new;
            errResp.statusCode = 400;
            errResp.setJsonPayload({"^error":"Invalid request payload "});
            var err = caller->respond(errResp);
            handleResponseError(err);
            return;
        }
        // Define a variables for response payload and status code
        json resp = {status:""};
        int statusCode;
        // Check whether student is qualified or not
        if (isQualified) {
            // Call qualified student records persistance service
            var response = stdInfoEP->post("/v2/5b2cc4292f00007900ebd395", req);
            if (response is http:Response) {
                statusCode = response.statusCode;
                // Set response status to Qualified
                resp.status = "Qualified";
            } else {
                log:printError("Invalid response", err = response);
            }
        } else {
            // Set response status to Not Qualified
            resp.status = "Not Qualified";
        }

        // Set JSON response
        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload(untaint resp);
        var err = caller->respond(res);
        handleResponseError(err);
    }
}

function handleResponseError(error? err) {
    if (err is error) {
        log:printError("Respond failed", err = err);
    }
}
