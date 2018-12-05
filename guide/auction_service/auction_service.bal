import ballerina/http;
import ballerina/io;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;
//
//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"auction_service",
//    tag:"v1.0"
//}
//
//@docker:Expose{}
//
//
//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-auction-service",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-auction-service"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/auction_service:v1.0",
//    name:"ballerina-guides-auction-service"
//}
// Service endpoint
listener http:Listener auctionEP = new(9090);

//Client endpoint to communicate with bidders.
http:Client biddersEP1 = new("http://localhost:9091/bidders");

// Auction service to get highest bid from bidders.
@http:ServiceConfig { basePath: "/auction" }
service auctionService on auctionEP {

    // Resource to get highest bid value.
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function setAuction(http:Caller caller, http:Request inRequest) {
        http:Response outResponse = new;
        json inReqPayload;
        var payload = inRequest.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload.
            inReqPayload = untaint payload;
        } else {
            // NOT a valid JSON payload.
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        json Item = inReqPayload.Item;
        json Condition = inReqPayload.Condition;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (Item == null || Condition == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({ "Message": "Bad Request - Invalid Payload" });
            var result = caller->respond(outResponse);
            handleError(result);
            return;
        }

        json jsonResponseBidder1 = {};
        json jsonResponseBidder2 = {};
        json jsonResponseBidder3 = {};
        json jsonHighestBid = {};

        fork {
            // Worker to communicate with 'Bidder 1'.
            worker bidder1Worker returns http:Response|error {
                http:Request outReq = new;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 1' and get the results.
                var respWorkerBidder1 = biddersEP1->post("/bidder1", outReq);
                return respWorkerBidder1;
            }
            // Worker to communicate with 'Bidder 2'.
            worker bidder2Worker returns http:Response|error {
                http:Request outReq = new;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 2' and get the results.
                var respWorkerBidder2 = biddersEP1->post("/bidder2", outReq);
                return respWorkerBidder2;
            }

            // Worker to communicate with 'Bidder 3'.
            worker bidder3Worker returns http:Response|error {
                http:Request outReq = new;
                // Set the out request payload.
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 3' and get the results.
                var respWorkerBidder3 = biddersEP1->post("/bidder3", outReq);
                return respWorkerBidder3;
            }
        }

        // Wait until the responses received from all the workers running.
        map<http:Response|error> biddersResponses = wait {bidder1Worker, bidder2Worker, bidder3Worker};

        int bidder1Bid = 0;
        int bidder2Bid = 0;
        int bidder3Bid = 0;

        // Get the bid value response from bidder 1.
        var resBidder1 = biddersResponses["bidder1Worker"];
        if (resBidder1 is error) {
            panic resBidder1;
        } else if (resBidder1 is http:Response) {
            var jsonResp = resBidder1.getJsonPayload();
            if (jsonResp is json) {
                jsonResponseBidder1 = jsonResp;
            } else {
                panic(jsonResp);
            }
            var bid1 = jsonResponseBidder1.Bid;
            if (bid1 is int) {
                bidder1Bid = bid1;
            } else {
                bidder1Bid = -1;
            }
        }

        // Get the bid value response from bidder 2.
        var resBidder2 = biddersResponses["bidder2Worker"];
        if (resBidder2 is error) {
            panic(resBidder2);
        } else if (resBidder2 is http:Response) {
            var jsonResp = resBidder2.getJsonPayload();
            if (jsonResp is json) {
                jsonResponseBidder2 = jsonResp;
            } else {
                panic(jsonResp);
            }
            var bid2 = jsonResponseBidder2.Bid;
            if (bid2 is int) {
                bidder2Bid = bid2;
            } else {
                bidder2Bid = -1;
            }
        }

        // Get the bid value response from bidder 3.
        var resBidder3 = biddersResponses["bidder3Worker"];
        if (resBidder3 is error) {
            panic(resBidder3);
        } else if (resBidder3 is http:Response) {
            var jsonResp = resBidder3.getJsonPayload();
            if (jsonResp is json) {
                jsonResponseBidder3 = jsonResp;
            } else {
                panic(jsonResp);
            }
            var bid3 = jsonResponseBidder3.Bid;
            if (bid3 is int) {
                bidder3Bid = bid3;
            } else {
                bidder3Bid = -1;
            }
        }

        // Select the bidder with the highest bid.
        if (bidder1Bid > bidder2Bid) {
            if (bidder1Bid > bidder3Bid) {
                jsonHighestBid = untaint jsonResponseBidder1;
            }
        } else {
            if (bidder2Bid > bidder3Bid) {
                jsonHighestBid = untaint jsonResponseBidder2;
            }
            else {
                jsonHighestBid = untaint jsonResponseBidder3;
            }
        }
        // Send the final response to client.
        outResponse.setJsonPayload(jsonHighestBid);
        var result = caller->respond(outResponse);
        handleError(result);
    }
}

