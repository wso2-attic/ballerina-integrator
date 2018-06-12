# Scatter-Gather Messaging

A scatter-gather messaging is send a message to multiple recipients and re-aggregates the responses back into a single message.

> This guide walks you through the process of implementing a scatter-gather messaging using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understanding how you can build a scatter-gather messaging using Ballerina, let's consider a real-world use case of a online auction service that get the highest bid value from bidders. This package includes scatter-gather component for get highest bid value by processing responses and three bidder endpoints. Therefore, the online auction service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/images/scatter-gather-messaging.png)

Auction service is the service that acts as the scatter-gather component. The other three endpoints are external services that the auction service calls to get bid values according to the request details. These are not necessarily Ballerina services and can theoretically be third-party services that the auction service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
 - [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping  "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
scatter-gather-messaging
  └── guide
      ├── auction service
      │   ├── auction_service.bal
      │   └── tests
      │       └── auction_service_test.bal
      ├── bidders endpoint
         ├── bidders_endpoints.bal
         └── tests
             └── bidders_endpoints_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `scatter-gather-messaging/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the service

Let's look at the implementation of the auction service, which acts as the scatter-gather component.


In this implementation to get a best bid value, auction service requires communicating with three other endpoints: bidder1, bidder2, bidder3. All these endpoints accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:
```bash
{"Item":"car","Condition":"good"};
```

Sample response payload:

```bash
{"Bidder Name":"Bidder 2","Bid":470000}
```

When a auctioneer initiate a request to get highest bid value, the auction service need to send this request to all the bidders that are include in the system. To check the implementation of this bidders endpoints, see the [bidders_endpoints.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/bidders/bidders_endpoints.bal) file.

If all bidders endpoints work successfully, the auction service proceed to get highest bid value and send back to the client(auctioneer) with the bidder name. The skeleton of `auction_service.bal` file is attached below. Inline comments are added for better understanding.
Refer to the [auction_service.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/auction%20service/auction_service.bal) to see the complete implementation of the auction service.

##### auction_service.bal

```ballerina
import ballerina/http;
import ballerina/io;

// Service endpoint
endpoint http:Listener auctionEP {
    port:9090
};

//Client endpoint to communicate with bidders
endpoint http:Client biddersEP {
    url:"http://localhost:9091/bidders"
};

// Auction service to get highest bid from bidders
@http:ServiceConfig {basePath:"/auction"}
service<http:Service> auctionService bind auctionEP {

    //Resource to get highest bid value
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], 
    produces: ["application/json"] }
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

	//Try parsing the JSON payload from the user request
	//Get the bid value from bidder 1
	//Get the bid value from bidder 2
	//Get the bid value from bidder 3
       
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
```

Let's now look at the code segment that is responsible for communicating with the all bidders endpoints.

```ballerina
fork {
            // Worker to communicate with 'Bidder 1'
            worker bidder1Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 1' and get the results
                http:Response respWorkerBidder1 = check biddersEP->post("/bidder1", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Bidder1'
                respWorkerBidder1 -> fork;
            }
            // Worker to communicate with 'Bidder 2'
            worker bidder2Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 2' and get the results
                http:Response respWorkerBidder2 = check biddersEP -> post("/bidder2", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Bidder 2'
                respWorkerBidder2 -> fork;
            }

            // Worker to communicate with 'Bidder 3'
            worker bidder3Worker {
                http:Request outReq;
                // Set out request payload
                outReq.setJsonPayload(inReqPayload);
                // Send a POST request to 'Bidder 3' and get the results
                http:Response respWorkerBidder3 = check biddersEP -> post("/bidder3", request = outReq);
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

```

The above code shows how the auction service initiates a request to all bidders that are include in the system to get their bid value.

## Testing 

### Invoking the service

- Navigate to `scatter-gather-messaging/guide` and run the following commands in separate terminals to start two HTTP services. This will start the `auctionService` and  `bidService` services in ports 9091, 9092 respectively.

```bash
   $ ballerina run auction_service/auction_service.bal
```
```bash
   $ ballerina run bidders/bidders_endpoints.bal
```
   
- Invoke the auction service by sending a POST request to get highest bid.

```bash
   curl -v -X POST -d '{"Item":"car","Condition":"good"}' "http://0.0.0.0:9090/auction/setAuction" 
   -H "Content-Type:application/json"
```

  Auction service will send a response similar to the following. That means ‘Bidder 3’ is the bidder gives the highest bid for particular item.
    
```bash
   < HTTP/1.1 200 OK
   {"Bidder Name":"Bidder 3","Bid":470000}
```
   
### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testAuctionService () {}
```
  
This guide contains unit test cases for each service implemented above. 

To run the tests, open your terminal and navigate to `scatter-gather-messaging/guide`, and run the following command.
```bash
   $ ballerina test
```

To check the implementations of these test files, refer to the [auction_service_test.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/tests/auction_service_test.bal), [bidders_endpoints_test.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/bidders/tests/bidders_endpoints_test.bal).

## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally

- As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `scatter-gather-messaging/guide` and run the following command. 
```bash
   $ ballerina build <Package_Name>
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output. 
```
   ballerina: initiating service(s) in 'target/guide.balx'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9091
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090

```
