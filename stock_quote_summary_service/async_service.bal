import ballerina/http;
import ballerina/io;
import ballerina/runtime;

@Description {value:"Attributes associated with the service endpoint is defined here."}
endpoint http:Listener asyncServiceEP {
    port:9090
};

@Description {value:"Service is to be exposed via HTTP/1.1."}
@http:ServiceConfig {
    basePath:"/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {

    @Description {value:"Resource for the GET requests of quote service"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    getQuote(endpoint caller, http:Request req) {
        // Endpoint for the stock quote backend service
        endpoint http:Client nasdaqServiceEP {
            url:"http://localhost:9095"
        };
        http:Request req = new;
        http:Response resp = new;
        string responseStr;
        // Initialize empty json to add results from backed call
        json  responseJson = {};

        io:println(" >> Invoking services asynchrnounsly...");

        // 'start' allows you to invoke a functions  asynchronously. Following three
        // remote invocation returns without waiting for response.

        // Calling the backend to get the stock quote for GOOG asynchronously
        future <http:Response|http:HttpConnectorError> f1 = start nasdaqServiceEP
        -> get("/nasdaq/quote/GOOG", request = req);

        io:println(" >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for APPL asynchronously
        future <http:Response|http:HttpConnectorError> f2 = start nasdaqServiceEP
        -> get("/nasdaq/quote/APPL", request = req);

        io:println(" >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for MSFT asynchronously
        future <http:Response|http:HttpConnectorError> f3 = start nasdaqServiceEP
        -> get("/nasdaq/quote/MSFT", request = req);

        io:println(" >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.");

        // ‘await` blocks until the previously started async function returns.
        // Append the results from all the responses of stock data backend
        var response1 = await f1;
        // Use `match` to check the responses are available, if not available get error
        match response1 {
            http:Response resp => {

                responseStr = check resp.getStringPayload();
                // Add the response from /GOOG endpoint to responseJson file
                responseJson["GOOG"] = responseStr;
            }
            http:HttpConnectorError err => {
                io:println(err.message);
                responseStr = err.message;
            }
        }

        var response2 = await f2;
        match response2 {
            http:Response resp => {
                responseStr = check resp.getStringPayload();
                // Add the response from /APPL endpoint to responseJson file
                responseJson["APPL"] = responseStr;
            }
            http:HttpConnectorError err => {
                io:println(err.message);
            }
        }

        var response3 = await f3;
        match response3 {
            http:Response resp => {
                responseStr = check resp.getStringPayload();
                // Add the response from /MSFT endpoint to responseJson file
                responseJson["MSFT"] = responseStr;

            }
            http:HttpConnectorError err => {
                io:println(err.message);
            }
        }

        // Send the response back to the client
        resp.setJsonPayload(responseJson);
        io:println(" >> Response : " + responseJson.toString());
        _ = caller -> respond(resp);
    }
}
