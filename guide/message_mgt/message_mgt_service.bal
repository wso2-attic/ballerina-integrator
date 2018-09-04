import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-message-mgt-service",
//    path:"/message-mgt",
//    targetPath:"/message-mgt"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-message-mgt-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/message_mgt_service:v1.0",
//    name:"ballerina-guides-message-mgt-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}


// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"message_mgt_service",
//    tag:"v1.0"
//}

//@docker:Expose{}


endpoint http:Listener listener {
    port: 9095
};

// Message management is done using an in-memory map.
// Add some sample messages to 'messageMap' at startup.
map<json> messageMap;


// RESTful service.
@http:ServiceConfig { basePath: "/message-mgt" }
service<http:Service> message_mgt_service bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/message"
    }
    addMessage(endpoint client, http:Request req) {

        log:printInfo("addMessage...");

        json messageReq = check req.getJsonPayload();
        string messageId = messageReq.Message.ID.toString();
        messageMap[messageId] = messageReq;

        // Create response message.
        json payload = { status: "Message Sent.", messageId: messageId };
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
        path: "/message/list"
    }
    getMessages(endpoint client, http:Request req) {

        log:printInfo("getMessages...");

        http:Response response = new;

        // Create a json array with Messages
        json messageResponse = { Messages: [] };

        // Get all Messages from map and add them to response
        int i = 0;
        foreach k, v in messageMap {
            json messageValue = v.Message;
            messageResponse.Messages[i] = messageValue;
            i++;
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint messageResponse);

        // Send response to the client.
        client->respond(response) but {
            error e => log:printError(
                           "Error sending response", err = e)
        };
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/unread-message/list"
    }
    getUnreadMessages(endpoint client, http:Request req) {

        log:printInfo("getUnreadMessages...");

        http:Response response = new;

        // Create a json array with Messages
        json messageResponse = { Messages: [] };

        // Get all Messages from map and add them to response
        int i = 0;
        foreach k, v in messageMap {
            json messageValue = v.Message;
            string messageStatus = messageValue.Status.toString();
            if (messageStatus == "Unread"){
                messageResponse.Messages[i] = messageValue;
                i++;
            }

        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint messageResponse);

        // Send response to the client.
        client->respond(response) but {
            error e => log:printError(
                           "Error sending response", err = e)
        };
    }

}
