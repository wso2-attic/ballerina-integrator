import ballerina/http;
import ballerina/io;

// Service endpoint
endpoint http:Listener auctionEP {
    port:9090
};

//Client endpoint to communicate with bidders
endpoint http:Client biddersEP1 {
    url:"http://localhost:9091/bidders"
};

// Auction service to get highest bid from bidders
@http:ServiceConfig {basePath:"/auction"}
service<http:Service> auctionService bind auctionEP {

    //Resource to get highest bid value
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    setAuction(endpoint client, http:Request inRequest) {
        http:Response outResponse;
        json inReqPayload;

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

        json Item = inReqPayload.Item;
        json Condition = inReqPayload.Condition;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (Item == null || Condition == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            done;
        }

        json jsonResponseBidder1;
        json jsonResponseBidder2;
        json jsonResponseBidder3;
        json jsonHighestBid;

        fork {
            // Worker to communicate with 'Bidder 1'
            worker bidder1Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 1' and get the results
                http:Response respWorkerBidder1 = check biddersEP1->post("/bidder1", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Bidder1'
                respWorkerBidder1 -> fork;
            }
            // Worker to communicate with 'Bidder 2'
            worker bidder2Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 2' and get the results
                http:Response respWorkerBidder2 = check biddersEP1 -> post("/bidder2", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Bidder 2'
                respWorkerBidder2 -> fork;
            }

            // Worker to communicate with 'Bidder 3'
            worker bidder3Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 3' and get the results
                http:Response respWorkerBidder3 = check biddersEP1 -> post("/bidder3", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Bidder 3'
                respWorkerBidder3 -> fork;
            }
        } join (all) (map biddersResponses) {
            // Wait until the responses received from all the workers running
            int bidder1Bid;
            int bidder2Bid;
            int bidder3Bid;

            // Get the bid value response from bidder 1
            if (biddersResponses["bidder1Worker"] != null) {
                var resBidder1 = check <http:Response>(biddersResponses["bidder1Worker"]);
                jsonResponseBidder1 = check resBidder1.getJsonPayload();
                match jsonResponseBidder1.Bid {
                    int intVal => bidder1Bid = intVal;
                    any otherVals => bidder1Bid = -1;
                }
            }

            // Get the bid value response from bidder 2
            if (biddersResponses["bidder2Worker"] != null) {
                var resBidder2 = check <http:Response>(biddersResponses["bidder2Worker"]);
                jsonResponseBidder2 = check resBidder2.getJsonPayload();
                match jsonResponseBidder2.Bid {
                    int intVal => bidder2Bid = intVal;
                    any otherVals => bidder2Bid = -1;
                }
            }

            // Get the bid value response from bidder 3
            if (biddersResponses["bidder3Worker"] != null) {
                var resBidder3 = check <http:Response>(biddersResponses["bidder3Worker"]);
                jsonResponseBidder3 = check resBidder3.getJsonPayload();
                match jsonResponseBidder3.Bid {
                    int intVal => bidder3Bid = intVal;
                    any otherVals => bidder3Bid = -1;
                }
            }

            // Select the bidder with the highest bid
            if (bidder1Bid > bidder2Bid) {
                if (bidder1Bid > bidder3Bid) {
                    jsonHighestBid = jsonResponseBidder1;
                }
            } else {
                if (bidder2Bid > bidder3Bid) {
                    jsonHighestBid = jsonResponseBidder2;
                }
                else {
                    jsonHighestBid = jsonResponseBidder3;
                }
            }
            // Send final response to client
            outResponse.setJsonPayload(jsonHighestBid);
            _ = client -> respond(outResponse);
        }


    }
}