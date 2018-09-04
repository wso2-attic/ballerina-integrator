import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerinax/kubernetes;

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


endpoint http:Listener listener {
    port: 9092
};

// Appointment management is done using an in-memory map.
// Add some sample appointments to 'appointmetMap' at startup.
map<json> appointmentMap;


// RESTful service.
@http:ServiceConfig { basePath: "/appointment-mgt" }
service<http:Service> appointment_mgt_service bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/appointment"
    }
    addAppointment(endpoint client, http:Request req) {

        log:printInfo("addAppointment...");

        json appointmentReq = check req.getJsonPayload();
        string appointmentId = appointmentReq.Appointment.ID.toString();
        appointmentMap[appointmentId] = appointmentReq;

        // Create response message.
        json payload = { status: "Appointment Created.", appointmentId: appointmentId };
        http:Response response;
        response.setJsonPayload(untaint payload);

        // Set 201 Created status code in the response message.
        response.statusCode = 201;

        // Send response to the client.
        _ = client->respond(response) but {
            error e => log:printError(
                           "Error sending response", err = e)
        };
    }


    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointment/list"
    }
    getAppointments(endpoint client, http:Request req) {
        log:printInfo("getAppointments...");

        http:Response response = new;

        // Create a json array with Appointments
        json appointmentsResponse = { Appointments: [] };

        // Get all Appointments from map and add them to response
        int i = 0;
        foreach k, v in appointmentMap {
            json appointmentValue = v.Appointment;
            appointmentsResponse.Appointments[i] = appointmentValue;
            i++;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint appointmentsResponse);

        // Send response to the client.
        client->respond(response) but {
            error e => log:printError(
                           "Error sending response", err = e)
        };
    }


}
