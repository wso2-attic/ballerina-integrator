import ballerina/http;
import ballerina/runtime;
import ballerina/log;

# Attributes associated with the service endpoint are defined here.
listener http:Listener httpListener = new(9095);

# By default Ballerina assumes that the service is to be exposed via HTTP/1.1.
@http:ServiceConfig {
    basePath: "/nasdaq/quote"
}
service StockDataService on httpListener {

    # Resource to handle GET requests for GOOG stock quote.
    #
    # + caller - Represents the remote client's endpoint
    # + request - Represents the client request
    @http:ResourceConfig {
        path: "/GOOG",
        methods: ["GET"]
    }
    resource function googleStockQuote(http:Caller caller, http:Request request) {
        http:Response response = new;
        string googQuote = "GOOG, Alphabet Inc., 1013.41";
        response.setTextPayload(googQuote);
        var result = caller->respond(response);
        HandleError(result);
    }

    # Resource to handle GET requests for APPL stock quote.
    #
    # + caller - Represents the remote client's endpoint
    # + request - Represents the client request
    @http:ResourceConfig {
        path: "/APPL",
        methods: ["GET"]
    }
    resource function appleStockQuote(http:Caller caller, http:Request request) {
        http:Response response = new;
        string applQuote = "APPL, Apple Inc., 165.22";
        response.setTextPayload(applQuote);
        var result = caller->respond(response);
        HandleError(result);
    }

    # Resource to handle GET requests for MSFT stock quote.
    #
    # + caller - Represents the remote client's endpoint
    # + request - Represents the client request
    @http:ResourceConfig {
        path: "/MSFT",
        methods: ["GET"]
    }
    resource function msftStockQuote(http:Caller caller, http:Request request) {
        http:Response response = new;
        string msftQuote = "MSFT, Microsoft Corporation, 95.35";
        response.setTextPayload(msftQuote);
        var result = caller->respond(response);
        HandleError(result);
    }
}

function HandleError(error? result) {
    if (result is error) {
        log:printError("Error sending response", err = result);
    }
}
