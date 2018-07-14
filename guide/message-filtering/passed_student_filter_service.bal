import ballerina/http;
//import ballerinax/docker;
//import ballerinax/kubernetes;

// @docker:Config {
//     registry:"ballerina.guides.io",
//     name:"passed_student_filter_service",
//     tag:"v1.0"
// }

//  @docker:Expose{}

// @kubernetes:Ingress {
//     hostname:"ballerina.guides.io",
//     name:"ballerina-guides-passed_student_filter_service",
//     path:"/"
// }

// @kubernetes:Service {
//     serviceType:"NodePort",
//     name:"ballerina-guides-passed_student_filter_service"
// }

// @kubernetes:Deployment {
//     image:"ballerina.guides.io/passed_student_filter_service:v1.0",
//     name:"ballerina-guides-passed_student_filter_service"
// }

endpoint http:Listener filterServiceEP {
    port: 9090
};

endpoint http:Client stdInfoEP {
    url: "http://www.mocky.io"
};

// REST service to select the passed student from an exam
service<http:Service> filterService bind filterServiceEP {

    // Resource that handle HTTP POST request with JSON payload
    // Response with JSON payload
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }

    filterMarks (endpoint caller, http:Request request) {
        http:Response response;

        // Get the JSON payload from the request
        json reqPayload = check request.getJsonPayload();

        // Get the information of the subjects
        string stdName = check <string>reqPayload.name;
        json subjects = reqPayload.subjects;

        // Declare boolian flag to set Qualified or Not
        boolean isQualified = false;

        // Iterating subject array
        foreach subj in subjects {
            int mark = check <int>subj.marks;
            // Check the student exceed the pass mark value
            if (mark >= 60) {
                isQualified = true;
            }else{
                isQualified = false;
            }
        }
        // Set Original payload to a new request object
        http:Request req = new;
        req.setJsonPayload(untaint reqPayload);

        // Define a variables for response payload and status code
        json resp = {status:""};
        int statusCode;

        // Check whether student is qualified or not
        if(isQualified){
            // Call qualified student records persistance service
            response = check stdInfoEP -> post("/v2/5b2cc4292f00007900ebd395", req);
            statusCode = response.statusCode;
            // Set response status to Qualified
            resp.status = "Qualified";
        }else{
            // Set response status to Not Qualified
            resp.status = "Not Qualified";
        }

        // Set JSON response
        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload(untaint resp);
        _ = caller -> respond(res);
    }

}