import ballerina/http;
import ballerina/log;
// import ballerinax/docker;
// import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-medical-records-service",
//    path:"/medical-records",
//    targetPath:"/medical-records"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-medical-records-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/medical_records_service:v1.0",
//    name:"ballerina-guides-medical-records-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"medical_record_mgt_service",
//    tag:"v1.0"
//}

//@docker:Expose{}
listener http:Listener httpListener = new(9093);

// Medical Record management is done using an in-memory map.
// Add some sample Medical Records to 'medicalRecordMap' at startup.
map<json> medicalRecordMap = {};

// RESTful service.
@http:ServiceConfig { basePath: "/medical-records" }
service medical_record_mgt_service on httpListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/medical-record"
    }
    resource function addMedicalRecord(http:Caller caller, http:Request req) {

        log:printInfo("addMedicalRecord...");

        json medicalRecordtReq = checkpanic req.getJsonPayload();
        string medicalRecordId = medicalRecordtReq.MedicalRecord.ID.toString();
        medicalRecordMap[medicalRecordId] = medicalRecordtReq;

        // Create response message.
        json payload = { status: "Medical Record Created.", medicalRecordId: medicalRecordId };
        http:Response response = new();
        response.setJsonPayload(untaint payload);

        // Set 201 Created status code in the response message.
        response.statusCode = 201;

        // Send response to the client.
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/medical-record/list"
    }
    resource function getMedicalRecords(http:Caller caller, http:Request req) {
        log:printInfo("getMedicalRecords...");

        http:Response response = new;
        json medicalRecordsResponse = { MedicalRecords: [] };

        // Get all Medical Records from map and add them to response
        int i = 0;
        foreach var(k, v) in medicalRecordMap {
            json medicalRecordValue = v.MedicalRecord;
            medicalRecordsResponse.MedicalRecords[i] = medicalRecordValue;
            i += 1;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint medicalRecordsResponse);

        // Send response to the client.
        checkpanic caller->respond(response);
    }
}
