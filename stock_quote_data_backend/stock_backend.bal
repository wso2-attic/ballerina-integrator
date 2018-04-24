import ballerina/http;
import ballerina/io;
import ballerina/runtime;

@Description {value:"Attributes associated with the service endpoint are defined here."}
endpoint http:Listener listener {
    port:9095
};

@Description {value:"By default Ballerina assumes that the service is to be exposed via HTTP/1.1."}
@http:ServiceConfig {basePath:"/nasdaq/quote"}
service<http:Service> StockDataService bind listener {

    @Description {value:"Resource to handle GET requests for GOOG stock quote"}
    @http:ResourceConfig {
        path:"/GOOG", methods:["GET"]
    }
    googleStockQuote(endpoint caller, http:Request request) {
        http:Response response = new;
        string googQuote = "GOOG, Alphabet Inc., 1013.41";
        response.setStringPayload(googQuote);
        _ = caller -> respond(response);
    }

    @Description {value:"Resource to handle GET requests for APPL stock quote"}
    @http:ResourceConfig {
        path:"/APPL", methods:["GET"]
    }
    appleStockQuote(endpoint caller, http:Request request) {
        http:Response response = new;
        string applQuote = "APPL, Apple Inc., 165.22";
        response.setStringPayload(applQuote);
        _ = caller -> respond(response);
    }

    @Description {value:"Resource to handle GET requests for MSFT stock quote"}
    @http:ResourceConfig {
        path:"/MSFT", methods:["GET"]
    }
    msftStockQuote(endpoint caller, http:Request request) {
        http:Response response = new;
        string msftQuote = "MSFT, Microsoft Corporation, 95.35";
        response.setStringPayload(msftQuote);
        _ = caller -> respond(response);
    }
}