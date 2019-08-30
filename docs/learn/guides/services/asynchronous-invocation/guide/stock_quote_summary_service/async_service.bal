import ballerina/http;
import ballerina/log;
import ballerina/runtime;
import ballerina/io;

# Attributes associated with the service endpoint is defined here.
listener http:Listener asyncServiceEP = new(9090);

# Service is to be exposed via HTTP/1.1.
@http:ServiceConfig {
    basePath:"/quote-summary"
}
service AsyncInvoker on asyncServiceEP {

    # Resource for the GET requests of quote service.
    #
    # + caller - Represents the remote client's endpoint
    # + req - Represents the client request
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function getQuote(http:Caller caller, http:Request req) {
        // Endpoint for the stock quote backend service
        http:Client nasdaqServiceEP = new("http://localhost:9095");
        http:Response finalResponse = new;
        string responseStr = "";

        log:printInfo(" >> Invoking services asynchrnounsly...");

        // 'start' allows you to invoke a functions  asynchronously. Following three
        // remote invocation returns without waiting for response.

        // Calling the backend to get the stock quote for GOOG asynchronously
        future<http:Response|error> f1 = start nasdaqServiceEP->get("/nasdaq/quote/GOOG");

        log:printInfo(" >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.");

        // Calling the backend to get the stock quote for APPL asynchronously
        future<http:Response|error> f2 = start nasdaqServiceEP
        -> get("/nasdaq/quote/APPL");

        log:printInfo(" >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.");

        // Calling the backend to get the stock quote for MSFT asynchronously
        future<http:Response|error> f3 = start nasdaqServiceEP
        -> get("/nasdaq/quote/MSFT");

        log:printInfo(" >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.");

        // Initialize empty json to add results from backed call
        json responseJson = ();

        // ‘wait` blocks until the previously started async function returns.
        // Append the results from all the responses of stock data backend
        var response1 = wait f1;
        if (response1 is http:Response) {
            var payload = response1.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrive the payload");
            }
            // Add the response from /GOOG endpoint to responseJson file
            responseJson["GOOG"] = responseStr;
        } else {
            string errorMsg = <string>response1.detail().message;
            log:printError(errorMsg);
            responseJson["GOOG"] = errorMsg;
        }

        var response2 = wait f2;
        if (response2 is http:Response) {
            var payload = response2.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrive the payload");
            }
            // Add the response from /APPL endpoint to responseJson file
            responseJson["APPL"] = responseStr;
        } else {
            string errorMsg = <string>response2.detail().message;
            log:printError(errorMsg);
            responseJson["APPL"] = errorMsg;
        }

        var response3 = wait f3;
        if (response3 is http:Response) {
            var payload = response3.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrive the payload");
            }
            // Add the response from /MSFT endpoint to responseJson file
            responseJson["MSFT"] = responseStr;

        } else {
            string errorMsg = <string>response3.detail().message;
            log:printError(errorMsg);
            responseJson["MSFT"] = errorMsg;
        }

        // Send the response back to the client
        finalResponse.setJsonPayload(untaint responseJson);
        log:printInfo(" >> Response : " + responseJson.toString());
        var result = caller -> respond(finalResponse);
        if (result is error){
            log:printError("Error sending response", err = result);
        }
    }
}
