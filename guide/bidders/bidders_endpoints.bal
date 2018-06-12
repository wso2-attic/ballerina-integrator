import ballerina/io;
import ballerina/http;

//Service endpoint
endpoint http:Listener biddersEP {
    port:9091
};

// Bidders endpoints service
@http:ServiceConfig {basePath:"/bidders"}
service<http:Service> bidService bind biddersEP {

    // Resource 'bidder1', which checks the item condition and set 'bidder 1' bid value
    @http:ResourceConfig {methods:["POST"], path:"/bidder1", consumes:["application/json"],
        produces:["application/json"]}
    bidder1(endpoint client, http:Request inRequest) {
        http:Response outResponse;
        json inReqPayload;
        int bid;

        match inRequest.getJsonPayload() {
            // Valid JSON payload
            json payload => inReqPayload = payload;
            // NOT a valid JSON payload
            any => {
                outResponse.statusCode = 400;
                outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(outResponse);
                done;
            }
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (Item == null || Condition == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            done;
        }

        //Check the item condition and set the appropriate bid value
        if (Condition == "good"){
            bid = 350000;
        }

        if (Condition == "bad"){
            bid = 33000;
        }

        json BidDetails = {
            "Bidder Name":"Bidder 1",
            "Bid":bid
        };

        // Response payload
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller
        _ = client -> respond(outResponse);
        done;
    }

    // Resource 'bidder2', which checks the item condition and set 'bidder 2' bid value
    @http:ResourceConfig {methods:["POST"], path:"/bidder2", consumes:["application/json"],
        produces:["application/json"]}
    bidder2(endpoint client, http:Request inRequest) {
        http:Response outResponse;
        json inReqPayload;
        int bid;

        match inRequest.getJsonPayload() {
            // Valid JSON payload
            json payload => inReqPayload = payload;
            // NOT a valid JSON payload
            any => {
                outResponse.statusCode = 400;
                outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(outResponse);
                done;
            }
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (Item == null || Condition == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            done;
        }

        //Check the item condition and set the appropriate bid value
        if (Condition == "good"){
            bid = 470000;
        }

        if (Condition == "bad"){
            bid = 42000;
        }

        json BidDetails = {
            "Bidder Name":"Bidder 2",
            "Bid":bid
        };

        // Response payload
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller
        _ = client -> respond(outResponse);
        done;
    }

    // Resource 'bidder3', which checks the item condition and set 'bidder 3' bid value
    @http:ResourceConfig {methods:["POST"], path:"/bidder3", consumes:["application/json"],
        produces:["application/json"]}
    bidder3(endpoint client, http:Request inRequest) {
        http:Response outResponse;
        json inReqPayload;
        int bid;

        match inRequest.getJsonPayload() {
            // Valid JSON payload
            json payload => inReqPayload = payload;
            // NOT a valid JSON payload
            any => {
                outResponse.statusCode = 400;
                outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(outResponse);
                done;
            }
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (Item == null || Condition == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            done;
        }

        //Check the item condition and set the appropriate bid value
        if (Condition == "good"){
            bid = 440000;
        }

        if (Condition == "bad"){
            bid = 43000;
        }

        json BidDetails = {
            "Bidder Name":"Bidder 3",
            "Bid":bid
        };

        // Response payload
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller
        _ = client -> respond(outResponse);
        done;
    }
}