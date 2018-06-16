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
        json marksReq = check request.getJsonPayload();

        // Get the student array from the request payload
        json students = marksReq.students;
        int length = lengthof students; 

        // Created a empty JSON array to add passed student's information
        json filteredStudents = {students:[]};
        int i=0;

        // Iteratting student array
        foreach student in students {
            json marks = student.marks;
            int mark = check <int>marks;
            // Check the student exceed the pass mark value
            if (mark > 60) {
                // Create a new JSOn object for each filterd student record
                json<Student> filteredStudent = {};

                // Adding passed student's information to JSON object
                filteredStudent.name = student.name;
                filteredStudent.mark = mark;

                // Adding student filtered student's JSON object to JSON array
                filteredStudents.students[i] = filteredStudent;
                i++;
            }
        }
        //xml xmlPayload = check filteredStudents.toXML({});
        //io:println(xmlPayload);

        // Set JSON response
        response.setJsonPayload(filteredStudents, contentType = "application/json");
        _ = caller -> respond(response);
    }

}


// Defined Student type
type Student {
    string name;
    int mark;
};