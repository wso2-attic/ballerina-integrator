[![Build Status](https://travis-ci.org/ballerina-guides/scatter-gather-messaging.svg?branch=master)](https://travis-ci.org/ballerina-guides/scatter-gather-messaging)


# Scatter-Gather Messaging

Scatter-gather messaging is used send a message to multiple recipients and re-aggregates the responses back into a single message.

> This guide walks you through the process of implementing scatter-gather messaging using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understand how you can build scatter-gather messaging using Ballerina, let's consider a real-world use case of an online auction service that gets the highest bid value from bidders. This package includes a scatter-gather component to get the highest bid value by processing responses and three bidder endpoints. Therefore, the online auction service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/resources/scatter-gather-messaging.svg)

Auction service is the service that acts as the scatter-gather component. The other three endpoints are external services that the auction service calls to get bid values according to the request details. These are not necessarily Ballerina services and can theoretically be third-party services that the auction service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina) 

### Optional requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the GitHub repo and directly move to the "Testing" section by skipping  the "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
scatter-gather-messaging
   └── guide
       ├── scatter-gather-messaging
           │
           ├── auction_service
           │   ├── auction_service.bal	
           │   ├── bidders_endpoints.bal
           │   ├── tests
                     └── auction_service_test.bal
```

Create the above directories in your local machine and also create empty `.bal` files.

Open the terminal and navigate to `scatter-gather-messaging/guide` and run the Ballerina project initializing toolkit.

```bash
   $ ballerina init
```

### Developing the service

Let's look at the implementation of the auction service, which acts as the scatter-gather component.

In this implementation to get a best bid value, the auction service requires communicating with three other endpoints: bidder1, bidder2, and bidder3. All these endpoints accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:

```
{"Item":"car","Condition":"good"};
```

Sample response payload:

```
{"Bidder Name":"Bidder 2","Bid":470000}
```

When a auctioneer initiates a request to get the highest bid value, the auction service needs to send this request to all the bidders that are included in the system. To check the implementation of this bidders endpoints, see the [bidders_endpoints.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/auction_service/bidders_endpoints.bal) file.

If all the endpoints of bidders work successfully, the auction service proceeds to get highest bid value and send it back to the client (auctioneer) with the bidder name. The skeleton of the `auction_service.bal` file is attached below. Inline comments are added for better understanding.

Refer to the [auction_service.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/auction_service/auction_service.bal) to see the complete implementation of the auction service.

##### auction_service.bal

```ballerina
import ballerina/http;
import ballerina/io;
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

// Client endpoint to communicate with bidders.
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
               // Set out request payload.
               outReq.setJsonPayload(inReqPayload);
               // Send a POST request to 'Bidder 2' and get the results.
               var respWorkerBidder2 = biddersEP1->post("/bidder2", outReq);
               return respWorkerBidder2;
           }

           // Worker to communicate with 'Bidder 3'.
           worker bidder3Worker returns http:Response|error {
               http:Request outReq = new;
               // Set out request payload
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
       // Send final response to client.
       outResponse.setJsonPayload(jsonHighestBid);
       var result = caller->respond(outResponse);
       handleError(result);
       return ();
   }
}

```

Let's now look at the code segment that is responsible for communicating with all the endpoints of the bidders.

```ballerina
    fork {
        // Worker to communicate with 'Bidder 1'
        worker bidder1Worker returns http:Response|error {
            http:Request outReq = new;
            // Set out request payload
            outReq.setJsonPayload(inReqPayload);
            // Send a POST request to 'Bidder 1' and get the results
            var respWorkerBidder1 = biddersEP1->post("/bidder1", outReq);
            return respWorkerBidder1;
        }
        // Worker to communicate with 'Bidder 2'
        worker bidder2Worker returns http:Response|error {
            http:Request outReq = new;
            // Set out request payload
            outReq.setJsonPayload(inReqPayload);
            // Send a POST request to 'Bidder 2' and get the results
            var respWorkerBidder2 = biddersEP1->post("/bidder2", outReq);
            return respWorkerBidder2;
        }

        // Worker to communicate with 'Bidder 3'
        worker bidder3Worker returns http:Response|error {
            http:Request outReq = new;
            // Set out request payload
            outReq.setJsonPayload(inReqPayload);
            // Send a POST request to 'Bidder 3' and get the results
            var respWorkerBidder3 = biddersEP1->post("/bidder3", outReq);
            return respWorkerBidder3;
        }
    }

    // Wait until the responses received from all the workers running
    map<http:Response|error> biddersResponses = wait {bidder1Worker, bidder2Worker, bidder3Worker};

    int bidder1Bid = 0;
    int bidder2Bid = 0;
    int bidder3Bid = 0;

    // Get the bid value response from bidder 1
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
    
    // Get the bid value response from bidder 2
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
    
    // Get the bid value response from bidder 3
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
```

The above code shows how the auction service initiates a request to all bidders that are included in the system to get their bid value.

## Testing 

### Invoking the service

Navigate to `scatter-gather-messaging/guide` and run the following commands in a separate terminal to start two HTTP services. This will start the `auctionService` and  `bidService` services in ports 9091 and 9090 respectively.

```bash
   $ ballerina run auction_service
```
   
Invoke the auction service by sending a POST request to get the highest bid.

```bash
   $ curl -v -X POST -d '{"Item":"car","Condition":"good"}' "http://0.0.0.0:9090/auction/setAuction" \
   -H "Content-Type:application/json"
```

The auction service sends a response similar to the following. That means ‘Bidder 3’ is the bidder that makes the highest bid for that particular item.
    
```
< HTTP/1.1 200 OK
{"Bidder Name":"Bidder 2", "Bid":470000}
```
   
### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.

Test functions should be annotated with `@test:Config`. See the below example.

```ballerina
@test:Config
function testAuctionService() {}
```
  
This guide contains unit test cases for each service implemented above. 

To run the tests, open your terminal, navigate to `scatter-gather-messaging/guide`, and run the following command.

```bash
   $ ballerina test
```

To check the implementations of these test files, refer to the [auction_service_test.bal](https://github.com/HisharaPerera/scatter-gather-messaging/blob/master/guide/tests/auction_service_test.bal).

## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that you developed above. Navigate to `scatter-gather-messaging/guide` and run the following command. 

```bash
   $ ballerina build auction_service
```

Once the .balx files are created inside the target folder, you can run them using the following command. 

```bash
   $ ballerina run target/auction_service.balx  
```

The successful execution of a service will show us something similar to the following output. 

```
Initiating service(s) in 'target/auction_service.balx'
ballerina: started HTTP/WS endpoint 0.0.0.0:9091
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that you developed above as a Docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running Ballerina programs on containers, you just need to put the corresponding Docker annotations on your service code. 

Let's see how to deploy the auction_service you developed above on Docker. When invoking this service make sure that the other service (bidService) is also up and running. 

In the auction_service, you need to import `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation during the build time.

##### auction_service.bal

```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry: "ballerina.guides.io",
    name: "auction_service",
    tag: "v1.0"
}

@docker:Expose{}
// Service endpoint
listener http:Listener auctionEP = new(9090);

//Client endpoint to communicate with bidders
http:Client biddersEP1 = new("http://localhost:9091/bidders");

// Auction service to get highest bid from bidders
@http:ServiceConfig {basePath:"/auction"}
service auctionService on auctionEP {
``` 

Now you can build a Ballerina executable archive (.balx) of the service that you developed above using the following command. This will also create the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `scatter-gather-messaging/guide` and run the following command.  
  
```bash
   $ ballerina build auction_service
  
Run following command to start docker container:
   $ docker run -d -p 9090:9090 ballerina.guides.io/auction_service:v1.0
```

Once you successfully build the Docker image, you can run it with the `docker run` command that is shown in the previous step.  

```bash
   $ docker run -d -p 9090:9090 ballerina.guides.io/auction_service:v1.0
```

Here we run the Docker image with flag `-p <host_port>:<container_port>` so that we use the host port 9090 and the container port 9090. Therefore, you can access the service through the host port. 

Verify the Docker container is running with the use of `$ docker ps`. The status of the Docker container should be shown as 'Up'. 

You can access the service using the same cURL commands that you used above. 
 
```bash
   $ curl -v -X POST -d '{"Item":"car","Condition":"good"}' "http://0.0.0.0:9090/auction/setAuction" \
   -H "Content-Type:application/json"
```

### Deploying on Kubernetes

You can run the service that you developed above on Kubernetes. The Ballerina language offers native support for running a Ballerina program on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the Docker images. So, you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

Let's see how we can deploy our `auction_service` on Kubernetes. When invoking this service, make sure that the other service (bidService) is also up and running. 

First you need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable Kubernetes deployment for the service you developed above.

##### auction_service.bal

```ballerina
import ballerina/http;
import ballerina/io;
import ballerinax/docker;
import ballerinax/kubernetes;


@kubernetes:Ingress {
    hostname: "ballerina.guides.io",
    name: "ballerina-guides-auction-service",
    path: "/"
}

@kubernetes:Service {
    serviceType: "NodePort",
    name: "ballerina-guides-auction-service"
}

@kubernetes:Deployment {
    image: "ballerina.guides.io/auction_service:v1.0",
    name: "ballerina-guides-auction-service"
}
// Service endpoint.
listener http:Listener auctionEP = new(9090);

//Client endpoint to communicate with bidders.
http:Client biddersEP1 = new("http://localhost:9091/bidders");


// Auction service to get highest bid from bidders
@http:ServiceConfig {basePath: "/auction"}
service auctionService on auctionEP {  
```

Here you have used `@kubernetes:Deployment` to specify the Docker image name that is created as part of building this service. 

You have also specified `@kubernetes:Service` so that it creates a Kubernetes service that exposes the Ballerina service that is running on a Pod.  

In addition, you have used `@kubernetes:Ingress`, which is the external interface to access your service (with path `/` and host name `ballerina.guides.io`).

Now you can build a Ballerina executable archive (.balx) of the service that you developed above using the following command. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.

```bash
   $ ballerina build auction_service
  
Run following command to deploy kubernetes artifacts:  
   $ kubectl apply -f ./target/auction_service/kubernetes
```

You can verify that the Docker image that you specified in `@kubernetes:Deployment` is created using `docker images`. 

Also, the Kubernetes artifacts related our service are generated under `./target/auction_service/kubernetes`. 

Now you can create the Kubernetes deployment using the following command.

```bash
   $ kubectl apply -f ./target/kubernetes/auction_service
 
deployment.extensions "ballerina-guides-auction-service" created
ingress.extensions "ballerina-guides-auction-service" created
service "ballerina-guides-auction-service" created
```

You can verify if the Kubernetes deployment, service and ingress are running properly by using following Kubernetes commands. 

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:

```bash
   $ curl -v -X POST -d '{"Item":"car","Condition":"good"}' \
   "http://localhost:<Node_Port>/auction/setAuction" -H "Content-Type:application/json" 
```

Ingress:

Add `/etc/hosts` entry to match hostname. 

``` 
127.0.0.1 ballerina.guides.io
```

Access the service .

```bash
   $ curl -v -X POST -d '{"Item":"car","Condition":"good"}' \
   "http://ballerina.guides.io/auction/setAuction" -H "Content-Type:application/json" 
```

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc. However, observability is disabled by default via configurations. Observability can be enabled by adding the following configurations to the `ballerina.conf` file in `inter-process-communication/guide/`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

> **NOTE**: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations, default values are loaded as the other configuration parameters of metrics and tracing.


### Tracing 

You can monitor Ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.

Follow the steps below to use tracing with Ballerina.

You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described above.

```
[b7a.observability]

[b7a.observability.tracing]
enabled=true
name="jaeger"

[b7a.observability.tracing.jaeger]
reporter.hostname="localhost"
reporter.port=5775
sampler.param=1.0
sampler.type="const"
reporter.flush.interval.ms=2000
reporter.log.spans=true
reporter.max.buffer.spans=1000
```

Run Jaeger Docker image using the following command.

```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 -p14268:14268 jaegertracing/all-in-one:latest
```

Navigate to `scatter-gather-messaging/guide` and run the `auction_service` using the following command.

```bash
   $ ballerina run auction_service/
```

Observe the tracing using Jaeger UI using following URL.

```
http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with Ballerina. We will use Prometheus as the monitoring tool.

Follow the below steps to set up Prometheus and view metrics for auction_service.

You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under the `Observability` section.

```ballerina
[b7a.observability.metrics]
enabled=true
provider="micrometer"

[b7a.observability.metrics.micrometer]
registry.name="prometheus"

[b7a.observability.metrics.prometheus]
port=9700
hostname="0.0.0.0"
descriptions=false
step="PT1M"
```

Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.

```
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['172.17.0.1:9797']
```

> **NOTE**: Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`.
   
Run the Prometheus Docker image using the following command.

```bash
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
You can access Prometheus at the following URL.

```
http://localhost:19090/
```

> **NOTE**: Ballerina will by default have the following metrics for the HTTP server connector. You can enter the following expression in Prometheus UI.
>   -  http_requests_total
>   -  http_response_time


### Logging

Ballerina has a log package for logging to the console. You can import `ballerina/log` package and start logging. The following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

Start the Ballerina Service with the following command from `scatter-gather-messaging/guide`.

```bash
   $ nohup ballerina run auction_service/ &>> ballerina.log&
```

> **NOTE**: This writes the console log to the `ballerina.log` file in the `scatter-gather-messaging/guide` directory.

Start Elasticsearch using the following command.

```bash
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1 
```

> **NOTE**: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count`.
   
Start Kibana plugin for data visualization with Elasticsearch.

```bash
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.5.1     
```

Configure logstash to format the Ballerina logs.

i) Create a file named `logstash.conf` with the following content.

```
input {  
 beats{ 
     port => 5044 
 }  
}

filter {  
 grok{  
     match => { 
	 "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	 \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }  
 }  
}   

output {  
 elasticsearch{  
     hosts => "elasticsearch:9200"  
     index => "store"  
     document_type => "store_logs"  
 }  
}  
```

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`.
     
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name.
     
```bash
   $ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
   -it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
   -p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
```
  
Configure filebeat to ship the Ballerina logs.

i) Create a file named `filebeat.yml` with the following content.

```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```

> **NOTE**: Modify the ownership of `filebeat.yml` file using `$chmod go-w filebeat.yml` 

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`.   
        
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name.
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/message-filtering/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
```
 
Access Kibana to visualize the logs using the following URL.

```
   http://localhost:5601 
```
