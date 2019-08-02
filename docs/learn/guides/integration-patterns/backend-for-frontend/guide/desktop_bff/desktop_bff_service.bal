import ballerina/http;
import ballerina/log;
// import ballerinax/docker;
// import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-desktop-bff-service",
//    path:"/"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-desktop-bff-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/desktop_bff_service:v1.0",
//    name:"ballerina-guides-desktop-bff-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"desktop_bff_service",
//    tag:"v1.0"
//}

//@docker:Expose{}

listener http:Listener httpListener = new(9091);


// Client endpoint to communicate with appointment management service
// URL for Docker deployment
// url: "http://appointment-mgt-container:9092/appointment-mgt"
http:Client appointmentEP = new("http://localhost:9092/appointment-mgt");

// Client endpoint to communicate with medical record service
// URL for Docker deployment
// url: "http://medical-record-mgt-container:9093/medical-records"
http:Client medicalRecordEP = new("http://localhost:9093/medical-records");

// Client endpoint to communicate with notification management service
// URL for Docker deployment
// url: "http://notification-mgt-container:9094/notification-mgt"
http:Client notificationEP = new("http://localhost:9094/notification-mgt");

// Client endpoint to communicate with message management service
// URL for Docker deployment
// url: "http://message-mgt-container:9095/message-mgt"
http:Client messageEP = new("http://localhost:9095/message-mgt");

// RESTful service.
@http:ServiceConfig { basePath: "/desktop-bff" }
service desktop_bff_service on httpListener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/alerts"
    }
    resource function getAlerts(http:Caller caller, http:Request req) {

        // This will return all message and notifications
        log:printInfo("getAlerts...");

        // Call Notification API and get notification list
        json notificationList = sendGetRequest(notificationEP, "/notification/list");

        // Call Message API and get full message list
        json messageList = sendGetRequest(messageEP, "/message/list");

        // Generate the response from notification and message aggregation
        json alertJson = {};

        alertJson.Notifications = notificationList.Notifications;
        alertJson.Messages = messageList.Messages;

        // Set JSON payload to response
        http:Response response = new;
        response.setJsonPayload(untaint alertJson);

        // Send response to the client.
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments"
    }
    resource function getAppointments(http:Caller caller, http:Request req) {

        log:printInfo("getAppointments...");

        // Call Appointment API and get appointment list
        json appointmentList = sendGetRequest(appointmentEP, "/appointment/list");

        // Generate the response
        json appointmentJson = {};
        appointmentJson.Appointments = appointmentList.Appointments;

        // Set JSON payload to response
        http:Response response = new();
        response.setJsonPayload(untaint appointmentJson);

        // Send response to the client.
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/medical-records"
    }
    resource function getMedicalRecords(http:Caller caller, http:Request req) {

        log:printInfo("getMedicalRecords...");

        // Call Medical Record API and get medical record list
        json medicalRecordList = sendGetRequest(medicalRecordEP, "/medical-record/list");

        // Generate the response
        json medicalRecordJson = {};
        medicalRecordJson.MedicalRecords = medicalRecordList.MedicalRecords;

        // Set JSON payload to response
        http:Response response = new();
        response.setJsonPayload(untaint medicalRecordJson);

        // Send response to the client.
        checkpanic caller->respond(response);
    }

    // This API may have more resources for other functionalities
}

// Function which takes http client endpoint and context as a input
// This will call given endpoint and return a json response
function sendGetRequest(http:Client httpClient1, string context) returns (json) {

    http:Client client1 = httpClient1;
    var response = client1->get(context);
    json value = {};

    if (response is http:Response) {
        var msg = response.getJsonPayload();
        if (msg is json) {
            value = msg;
        } else {
            log:printError(msg.reason());
        }
    } else {
        log:printError(response.reason());
    }

    return value;
}
