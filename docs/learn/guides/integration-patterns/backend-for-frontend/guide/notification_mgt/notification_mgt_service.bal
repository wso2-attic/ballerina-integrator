import ballerina/http;
import ballerina/log;
// import ballerinax/docker;
// import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-notification-mgt-service",
//    path:"/notification-mgt",
//    targetPath:"/notification-mgt"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-notification-mgt-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/notification_mgt_service:v1.0",
//    name:"ballerina-guides-notification-mgt-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"notification_mgt_service",
//    tag:"v1.0"
//}

//@docker:Expose{}
listener http:Listener httpListener = new(9094);

// Notification management is done using an in-memory map.
// Add some sample notifications to 'notificationMap' at startup.
map<json> notificationMap = {};

// RESTful service.
@http:ServiceConfig { basePath: "/notification-mgt" }
service notification_mgt_service on httpListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notification"
    }
    resource function addNotification(http:Caller caller, http:Request req) {
        log:printInfo("addNotification...");

        var notificationReq = req.getJsonPayload();
        if (notificationReq is json) {
            string notificationId = notificationReq.Notification.ID.toString();
            notificationMap[notificationId] = notificationReq;

            // Create response message.
            json payload = { status: "Notification Created.", notificationId: notificationId };
            http:Response response = new();
            response.setJsonPayload(untaint payload);

            // Set 201 Created status code in the response message.
            response.statusCode = 201;
            // Send response to the client.
            checkpanic caller->respond(response);
        } else {
            log:printError("JSON Payload is expected", err = notificationReq);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/notification/list"
    }
    resource function getNotifications(http:Caller caller, http:Request req) {

        log:printInfo("getNotifications...");

        http:Response response = new;
        json notificationsResponse = { Notifications: [] };

        // Get all Notifications from map and add them to response
        int i = 0;
        foreach var(k, v) in notificationMap {
            json notificationValue = v.Notification;
            notificationsResponse.Notifications[i] = notificationValue;
            i += 1;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint notificationsResponse);

        // Send response to the client.
        checkpanic caller->respond(response);
    }
}
