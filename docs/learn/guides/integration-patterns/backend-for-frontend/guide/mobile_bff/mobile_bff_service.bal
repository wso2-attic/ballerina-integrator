import ballerina/http;
import ballerina/log;
// import ballerinax/docker;
// import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-mobile-bff-service",
//    path:"/mobile-bff",
//    targetPath:"/mobile-bff"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-mobile-bff-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/mobile_bff_service:v1.0",
//    name:"ballerina-guides-mobile-bff-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"mobile_bff_service",
//    tag:"v1.0"
//}

//@docker:Expose{}
listener http:Listener httpListener = new(9090);

// Client endpoint to communicate with appointment management service
// URL for Docker deployment
// url: "http://appointment-mgt-container:9092/appointment-mgt"
http:Client appointmentEP = new("http://localhost:9092/appointment-mgt");

// Client endpoint to communicate with medical record service
// URL for Docker deployment
// url: "http://medical-record-mgt-container:9093/medical-records"
http:Client medicalRecordEP = new("http://localhost:9093/medical-records");

// Client endpoint to communicate with message management service
// URL for Docker deployment
// url: "http://message-mgt-container:9095/message-mgt"
http:Client messageEP = new("http://localhost:9095/message-mgt");

// RESTful service.
@http:ServiceConfig { basePath: "/mobile-bff" }
service mobile_bff_service on httpListener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/profile"
    }
    resource function getUserProfile(http:Caller caller, http:Request req) {

        log:printInfo("getUserProfile...");

        // Call Appointment API and get appointment list
        json appointmentList = sendGetRequest(appointmentEP, "/appointment/list");

        // Call Medical Record API and get medical record list
        json medicalRecordList = sendGetRequest(medicalRecordEP, "/medical-record/list");

        // Call Message API and get unread message list
        json unreadMessageList = sendGetRequest(messageEP, "/unread-message/list");

        // Aggregate the responses to a JSON
        json profileJson = {};
        profileJson.Appointments = appointmentList.Appointments;
        profileJson.MedicalRecords = medicalRecordList.MedicalRecords;
        profileJson.Messages = unreadMessageList.Messages;

        // Set JSON payload to response
        http:Response response = new();
        response.setJsonPayload(untaint profileJson);

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
            log:printError(msg.reason(), err = msg);
        }
    } else {
        log:printError(response.reason(), err = response);
    }

    return value;
}
