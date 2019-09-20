import wso2/jms;
import ballerina/log;
import ballerina/http;
import ballerina/config;

@http:ServiceConfig {
    basePath: "/sendTo"
}
service protocol_switch on new http:Listener(config:getAsInt("LISTENER_PORT")) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/queue"
    }
    resource function callEps(http:Caller caller, http:Request req) {
        var requestPayload = req.getTextPayload();
        if (requestPayload is string) {
            var result = sendMsgToQueue(requestPayload);
            if (result is error) {
                log:printError("Error sending message to queue", err = result);
            } else {
                log:printInfo("Message sent to queue");
            }
            http:Response response = new;
            response.statusCode = 202;
            respondToClient(caller, response);
        } else {
            respondToClient(caller, createErrorResponse(400, "Not a valid text request payload"));
        }
    }
}

//method to produce a text message to a queue
function sendMsgToQueue(string reqMsg) returns error?{
    jms:Connection connection = check jms:createConnection({
                          initialContextFactory: config:getAsString("INITIAL_CONTEXT_FACTORY"),
                          providerUrl: config:getAsString("PROVIDER_URL")
                        });
    jms:Session session = check connection->createSession({acknowledgementMode: "AUTO_ACKNOWLEDGE"});
    jms:Destination queue = check session->createQueue("MyQueue");
    jms:MessageProducer producer = check session.createProducer(queue);
    jms:TextMessage msg = check session.createTextMessage(reqMsg);
    check producer->send(msg);
}

//util method to respond to a caller and handle error
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}

// util method to create error response
function createErrorResponse(int statusCode, string msg) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = statusCode;
    errorResponse.setPayload(msg);
    return errorResponse;
} 
