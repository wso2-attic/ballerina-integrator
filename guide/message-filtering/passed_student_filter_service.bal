import ballerina/http;
import ballerina/io;

endpoint http:Listener filterServiceEP {
    port: 9090
};

service<http:Service> filterService bind filterServiceEP {

    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }

    filterMarks (endpoint caller, http:Request request) {
        http:Response response;
        json marksReq = check request.getJsonPayload();
        json students = marksReq.students;
        int length = lengthof students; 
        json filteredStudents = {students:[]};
        int i=0;
        foreach student in students {
            json marks = student.marks;
            int mark = check <int>marks;
            if (mark > 60) {
                json<Student> filteredStudent = {};
                filteredStudent.name = student.name;
                filteredStudent.mark = mark;
                filteredStudents.students[i] = filteredStudent;
                i++;
            }
        }
        //xml xmlPayload = check filteredStudents.toXML({});
        //io:println(xmlPayload);
        response.setJsonPayload(filteredStudents, contentType = "application/json");
        _ = caller -> respond(response);
    }

}

type Student {
    string name;
    int mark;
};