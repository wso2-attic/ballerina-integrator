import ballerina/io;
import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;
//
//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"bidders",
//    tag:"v1.0"
//}
//
//@docker:Expose{}
//
//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-bidders-endpoints",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-bidders-endpoints"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/bidders_endpoints:v1.0",
//    name:"ballerina-guides-bidders-endpoints"
//}

// Service endpoint.
listener http:Listener biddersEP = new(9091);

// Bidders endpoints service.
@http:ServiceConfig { basePath: "/bidders" }
service bidService on biddersEP {

    // Resource 'bidder1', which checks the item condition and set 'bidder 1' bid value.
    @http:ResourceConfig { methods: ["POST"], path: "/bidder1", consumes: ["application/json"],
        produces: ["application/json"] }
    resource function bidder1(http:Caller caller, http:Request inRequest) {
        http:Response outResponse = new;
        json inReqPayload = {};
        int bid = 0;
        var payload = inRequest.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload.
            inReqPayload = payload;
        } else {
            // NOT a valid JSON payload.
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (Item == null || Condition == "") {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Bad Request - Invalid Payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        // Check the item condition and set the appropriate bid value.
        if (Condition == "good") {
            bid = 350000;
        }

        if (Condition == "bad") {
            bid = 33000;
        }

        json BidDetails = {
            "Bidder Name": "Bidder 1",
            "Bid": bid
        };

        // Response payload.
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller.
        var result = caller->respond(outResponse);
        handleError(result);
        return;
    }

    // Resource 'bidder2', which checks the item condition and set 'bidder 2' bid value.
    @http:ResourceConfig { methods: ["POST"], path: "/bidder2", consumes: ["application/json"],
        produces: ["application/json"] }
    resource function bidder2(http:Caller caller, http:Request inRequest) {
        http:Response outResponse = new;
        json inReqPayload = {};
        int bid = 0;
        var payload = inRequest.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload.
            inReqPayload = payload;
        }
        else {
            // NOT a valid JSON payload.
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (Item == null || Condition == "") {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Bad Request - Invalid Payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        //Check the item condition and set the appropriate bid value.
        if (Condition == "good") {
            bid = 470000;
        }

        if (Condition == "bad") {
            bid = 42000;
        }

        json BidDetails = {
            "Bidder Name": "Bidder 2",
            "Bid": bid
        };

        // Response payload.
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller.
        var result = caller->respond(outResponse);
        handleError(result);
        return;
    }

    // Resource 'bidder3', which checks the item condition and set 'bidder 3' bid value.
    @http:ResourceConfig { methods: ["POST"], path: "/bidder3", consumes: ["application/json"],
        produces: ["application/json"] }
    resource function bidder3(http:Caller caller, http:Request inRequest) {
        http:Response outResponse = new;
        json inReqPayload = {};
        int bid = 0;
        var payload = inRequest.getJsonPayload();
        if(payload is json) {
            // Valid JSON payload.
            inReqPayload = payload;
        } else {
            // NOT a valid JSON payload.
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        string Condition = inReqPayload.Condition.toString();
        json Item = inReqPayload.Item;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (Item == null || Condition == "") {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Bad Request - Invalid Payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        //Check the item condition and set the appropriate bid value.
        if (Condition == "good") {
            bid = 440000;
        }

        if (Condition == "bad") {
            bid = 43000;
        }

        json BidDetails = {
            "Bidder Name": "Bidder 3",
            "Bid": bid
        };

        // Response payload.
        outResponse.setJsonPayload(BidDetails);
        // Send the response to the caller.
        var result = caller->respond(outResponse);
        handleError(result);
        return;
    }
}


function handleError(error? result) {
    if (result is error) {
        log:printError(result.reason(), err = result);
    }
}
