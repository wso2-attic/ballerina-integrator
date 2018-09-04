import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerinax/kubernetes;

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


endpoint http:Listener listener {
    port: 9094
};

// Notification management is done using an in-memory map.
// Add some sample notifications to 'notificationMap' at startup.
map<json> notificationMap;


// RESTful service.
@http:ServiceConfig { basePath: "/notification-mgt" }
service<http:Service> notification_mgt_service bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notification"
    }
    addNotification(endpoint client, http:Request req) {

        log:printInfo("addNotification...");

        json notificationReq = check req.getJsonPayload();
        string notificationId = notificationReq.Notification.ID.toString();
        notificationMap[notificationId] = notificationReq;

        // Create response message.
        json payload = { status: "Notification Created.", notificationId: notificationId };
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
        path: "/notification/list"
    }
    getNotifications(endpoint client, http:Request req) {

        log:printInfo("getNotifications...");

        http:Response response = new;
        json notificationsResponse = { Notifications: [] };

        // Get all Notifications from map and add them to response
        int i = 0;
        foreach k, v in notificationMap {
            json notificationValue = v.Notification;
            notificationsResponse.Notifications[i] = notificationValue;
            i++;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint notificationsResponse);

        // Send response to the client.
        client->respond(response) but {
            error e => log:printError(
                           "Error sending response", err = e)
        };
    }


}
