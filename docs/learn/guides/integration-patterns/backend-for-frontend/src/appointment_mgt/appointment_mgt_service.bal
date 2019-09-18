import ballerina/http;
import ballerina/log;
// import ballerinax/docker;
// import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-appointment-mgt-service",
//    path:"/appointment-mgt",
//    targetPath:"/appointment-mgt"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-appointment-mgt-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/appointment_mgt_service:v1.0",
//    name:"ballerina-guides-appointment-mgt-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

// @docker:Config {
//    registry:"ballerina.guides.io",
//    name:"appointment_mgt_service",
//    tag:"v1.0"
//}

//@docker:Expose{}
listener http:Listener httpListener = new(9092);

// Appointment management is done using an in-memory map.
// Add some sample appointments to 'appointmetMap' at startup.
type Appointment record {
        string ID;
        int Name;
        string Location;
        string Time;
        string Description;
};
map<json> appointmentMap = {};
json finalPayload = "";

// RESTful service.
@http:ServiceConfig { basePath: "/appointment-mgt" }
service appointment_mgt_service on httpListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/appointment"
    }
    resource function addAppointment(http:Caller caller, http:Request req) {

        log:printInfo("addAppointment...");

        var appointmentReq = req.getJsonPayload();

        if (appointmentReq is json) {
            string appointmentId = appointmentReq.Appointment.ID.toString();
            appointmentMap[appointmentId] = appointmentReq;
            // Create response message.
            json payload = { status: "Appointment Created.", appointmentId: appointmentId };
            http:Response response = new();
            response.setJsonPayload(<@untainted> payload);

            // Set 201 Created status code in the response message.
            response.statusCode = 201;

            // Send response to the client.
            checkpanic caller->respond(response);
        } else {
            log:printError("Response is not JSON");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointment/list"
    }
    resource function getAppointments(http:Caller caller, http:Request req) {
        log:printInfo("getAppointments...");
        http:Response response = new;

        // Get all Appointments from map and add them to response
        map<json> appointmentsResponse = { Appointments: [] };

        foreach var v in appointmentMap {
            json appointmentValue = <json>v.Appointment;
             appointmentsResponse["Appointments"] = appointmentValue;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(<@untainted> appointmentsResponse);

        // Send response to the client.
        checkpanic caller->respond(response);
    }
    
}
