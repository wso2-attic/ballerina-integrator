import ballerina/http;
import ballerina/log;

service hello on new http:Listener(9090) {
    resource function sayHello(http:Caller caller, http:Request req) {
        var payload = req.getTextPayload();
        string userInput = "";
        if (payload is string) {
            userInput = "Hello " +untaint payload + "";
        } else {
            userInput = "Payload is empty ";
        }
        var result = caller->respond(userInput);

        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}
