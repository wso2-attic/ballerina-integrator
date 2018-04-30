# Asynchronous Invocations
[Asynchronous invocations](https://en.wikipedia.org/wiki/Asynchronous_method_invocation) or the asynchronous pattern is a design pattern in which the call site is not blocked while waiting for the code invoked to finish. Instead, the calling thread can use the result when the reply arrives.

> In this guide you will learn about building a web service with asynchronous RESTful calls. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build 

To understand how you can use asynchronous invocations with Ballerina, let’s consider a Stock Quote Summary service.

- The Stock Quote Summary service calls a remote backend to get the stock data.
- The Ballerina Stock Quote Summary service calls the remote backends of three separate endpoints asynchronously.
- Finally, the quote summary servie appends all the results from three backends and sends the responses to the client.


The following figure illustrates the scenario of the Stock Quote Summary service with asynchronous invocations. 

&nbsp;
&nbsp;
&nbsp;
&nbsp;

![async invocation](images/asynchronous-invocation.svg "Asynchronous Invocation")

&nbsp;
&nbsp;
&nbsp;
&nbsp;



- **Request Stock Summary** : You can send an HTTP GET request to the `http://localhost:9090/quote-summary` URL and retrieve the stock quote summary.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation


> If you want to skip the basics, you can download the git repo and directly move to the**Testing**section by skipping the**Implementation**section.


### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you require. For this example, let's use the following package structure.

```
asynchronous-invocation
    └── guide
        ├── stock_quote_data_backend
        │   ├── stock_backend.bal
        │   └── tests
        │       └── stock_backend_test.bal
        ├── stock_quote_summary_service
        │   ├── async_service.bal
        │   └── tests
        │       └── async_service_test.bal
        └── tests
            └── integration_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `asynchronous-invocation/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```
  
### Implement the Stock Quote Summary service with asyncronous invocations
>>>>>>> master

- We can get started with the Stock Quote Summary service, which is the RESTful service that serves the stock quote summary requests. This service receives the requests via the HTTP GET method from the clients.

- The Stock Quote Summary service calls three separate remote resources asynchronously.

- The Ballerina language supports function calls and client connector actions in order to execute asynchronously. The `start` keyword allows you to invoke the function asychronously. The `future` type allows you to have the result in the future. The program can proceed without any blocking after the asynchronous function invocation. The following statement calls the endpoint asynchronously.

  `future <http:Response|error> responseFuture = start nasdaqServiceEP -> get("/nasdaq/quote/MSFT", request = req);`

- Finally, the service appends all three responses and returns the stock quote summary to the client. To get the results from a asynchronous call,  the `await` keyword needs to be used. `await` blocks invocations until the previously started asynchronous invocations are completed.
The following statement receives the response from the future type.

  ` var response1 = check await f1;`

##### async_service.bal
```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/runtime;


@Description {value:"Attributes associated with the service endpoint are defined here."}
endpoint http:Listener asyncServiceEP {
    port: 9090
};


@Description {value:"This service is to be exposed via HTTP/1.1."}
@http:ServiceConfig {
    basePath: "/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {

    @Description {value:"The resource for the GET requests of the quote service."}

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    getQuote(endpoint caller, http:Request req) {
        // The endpoint for the Stock Quote Backend service.
        endpoint http:Client nasdaqServiceEP {
            url: "http://localhost:9095"
        };
        http:Request req = new;
        http:Response resp = new;
        string responseStr;
        
        // This initializes empty json to add results from the backend call.
        json  responseJson = {};
        
        io:println(" >> Invoking services asynchrnounsly...");

        // 'start' allows you to invoke a functions  asynchronously. Following three
        // remote invocation returns without waiting for response.

        // This calls the backend to get the stock quote for GOOG asynchronously.
        future <http:Response|http:HttpConnectorError> f1 = start nasdaqServiceEP
        -> get("/nasdaq/quote/GOOG", request = req);

        io:println(" >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.");
        req = new;

        // This calls the backend to get the stock quote for APPL asynchronously.
        future <http:Response|http:HttpConnectorError> f2 = start nasdaqServiceEP
        -> get("/nasdaq/quote/APPL", request = req);

        io:println(" >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.");
        req = new;

        // This calls the backend to get the stock quote for MSFT asynchronously.
        future <http:Response|http:HttpConnectorError> f3 = start nasdaqServiceEP
        -> get("/nasdaq/quote/MSFT", request = req);

        io:println(" >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.");

        // The ‘await` keyword blocks until the previously started async function returns.
        // Append the results from all the responses of the stock data backend.
        var response1 = await f1;
        // Use `match` to check whether the responses are available. If they are not available, an error is generated.
        match response1 {
            http:Response resp => {

                responseStr = check resp.getStringPayload();
                // Add the response from the `/GOOG` endpoint to the `responseJson` file.

                responseJson["GOOG"] = responseStr;
            }
            error err => {
                io:println(err.message);
                responseJson["GOOG"] = err.message;
            }
        }

        var response2 = await f2;
        match response2 {
            http:Response resp => {
            
                responseStr = check resp.getStringPayload();
                // Add the response from `/APPL` endpoint to `responseJson` file.
                responseJson["APPL"] = responseStr;
            }
            error err => {
                io:println(err.message);
                responseJson["APPL"] = err.message;
            }
        }

        var response3 = await f3;
        match response3 {
            http:Response resp => {
                responseStr = check resp.getStringPayload();
                // Add the response from the `/MSFT` endpoint to the `responseJson` file.
                responseJson["MSFT"] = responseStr;

            }
            error err => {
                io:println(err.message);
                responseJson["MSFT"] = err.message;
            }
        }

        // Send the response back to the client.
        resp.setJsonPayload(responseJson);
        io:println(" >> Response : " + responseJson.toString());
        _ = caller->respond(resp);
    }
}
```

### Mock remote service: stock_quote_data_backend

You can use any third-party remote service for the remote backend service. For ease of explanation, we have developed the mock stock quote remote backend with Ballerina. This mock stock data backend has the following resources and the respective responses.
 - resource path `/GOOG` with response `"GOOG, Alphabet Inc., 1013.41"` 
 - resource path `/APPL` with response `"APPL, Apple Inc., 165.22"` 
 - resource path `/MSFT` with response `"MSFT, Microsoft Corporation, 95.35"` 

NOTE: You can find the complete implementaion of the stock_quote_data_backend [here](stock_quote_data_backend/stock_backend.bal)

## Testing 

### Invoking stock quote summary service

- First, you need to run `stock_quote_data_backend`. To do this, navigate to the `<SAMPLE_ROOT>` directory and run the following command in the terminal.
```
$ballerina run stock_quote_data_backend/
```
NOTE: To run the Ballerina service, you need to have Ballerina installed in you local machine.

- Then, you need to run `stock_quote_summary_service`. To do this, navigate to the `<SAMPLE_ROOT>` directory and run the following command in the terminal.

```
$ballerina run stock_quote_summary_service/
```

- Now you can execute the following curl commands to call the stock quote summary service.

**Get stock quote summary for GOOG, APPL and MSFT** 

```
curl http://localhost:9090/quote-summary

Output :  
{
    "GOOG": "GOOG, Alphabet Inc., 1013.41",
    "APPL": "APPL, Apple Inc., 165.22",
    "MSFT": "MSFT, Microsoft Corporation, 95.35"
}
```

**Console output for stock_quote_summary_service(with asynchronous calls)**
```
 >> Invoking services asynchrnounsly...
 >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.
 >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.
 >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.
 >> Response : {
    "GOOG": "GOOG, Alphabet Inc., 1013.41",
    "APPL": "APPL, Apple Inc., 165.22",
    "MSFT": "MSFT, Microsoft Corporation, 95.35"
}
```

### Writing unit tests 


In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testQuoteService() {
```
  
This guide contains unit test cases for every all the packages inside the `asynchronous-invocation/guide` directory. 

To run all the tests, open your terminal and navigate to `asynchronous-invocation/guide`, and run the following command.

```bash
$ ballerina test
```

To check the implementation of the test file, refer tests folder in the [git repository](https://github.com/ballerina-guides/asynchronous-invocation).


## Deployment

Once you are done with the development, you can deploy the service using any of the methods that are listed below. 

### Deploying locally


- As the first step, you can build a Ballerina executable archive (.balx) of the service that is developed above. To do this, navigate to the `<SAMPLE_ROOT>/` directory and run the following commands. It points to the directory in which the service you developed is located, and creates an executable binary out of that. 


```
$ballerina build stock_quote_summary_service
```

```
$ballerina build stock_quote_data_backend
```

- Once the `stock_quote_summary_service.balx` and `build stock_quote_data_backend.balx` are created inside the target directory, issue the following command to execute them. 

```
$ballerina run target/stock_quote_summary_service.balx
```

```
$ballerina run target/stock_quote_data_backend.balx
```

- Once the service is successfully executed, the following output is displayed. 
```
$ballerina run target/stock_quote_summary_service.balx
ballerina: initiating service(s) in 'async_service.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

```
$ballerina run target/stock_quote_data_backend.balx
ballerina: initiating service(s) in 'stock_backend.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9095

```

### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 

- In our order_mgt_service, we need to import  `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable docker image generation during the build time. 

##### async_service.bal
```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"async_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
    port:9090
};

@Description { value: "Service is to be exposed via HTTP/1.1." }
@http:ServiceConfig {
    basePath: "/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {
``` 

- `@docker:Config` annotation is used to provide the basic docker image configurations for the sample. `@docker:Expose {}` is used to expose the port. 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to `asynchronous-invocation/guide` and run the following command.  
```
   $ ballerina build stock_quote_summary_service

   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/stock_quote_summary_service:v1.0
```

- Once you successfully build the docker image, you can run it with the `docker run` command that is shown in the previous step.  
```   
   $ docker run -d -p 9090:9090 ballerina.guides.io/stock_quote_summary_service:v1.0
```

  Here we run the docker image with flag `-p <host_port>:<container_port>` so that we  use  the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `$ docker ps`. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl commands that we've used above. 
```
curl http://localhost:9090/quote-summary
```

### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Let's now see how we can deploy our `stock_quote_summary_service` on Kubernetes.

- First we need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### order_mgt_service.bal

```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-asynchronous-invocation",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-asynchronous-invocation"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/asynchronous-invocation:v1.0",
    name:"ballerina-guides-asynchronous-invocation"
}

endpoint http:Listener listener {
    port:9090
};

@Description { value: "Service is to be exposed via HTTP/1.1." }
@http:ServiceConfig {
    basePath: "/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {
``` 

- Here we have used `@kubernetes:Deployment` to specify the docker image name which will be created as part of building this service. 
- We have also specified `@kubernetes:Service` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `@kubernetes:Ingress` which is the external interface to access your service (with path `/` and host name `ballerina.guides.io`)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build stock_quote_summary_service
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/stock_quote_summary_service/kubernetes
```

- You can verify that the docker image that we specified in `@kubernetes:Deployment` is created, by using `$ docker images`. 
- Also the Kubernetes artifacts related our service, will be generated in `./target/stock_quote_summary_service/kubernetes`. 
- Now you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/stock_quote_summary_service/kubernetes 
 
   deployment.extensions "ballerina-guides-asynchronous-invocation" created
   ingress.extensions "ballerina-guides-asynchronous-invocation" created
   service "ballerina-guides-asynchronous-invocation" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands.

```
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
  curl http://localhost:9090/quote-summary
```

Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service 
``` 
  curl http://localhost:9090/quote-summary
```

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file in `asynchronous-invocation/guide/`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations default values are load as the other configuration parameters of metrics and tracing.

### Tracing 

You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.

- You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described above.
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

- Run Jaeger docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `asynchronous-invocation/guide` and run the asynchronous-invocation using following command 
```
   $ ballerina run stock_quote_summary_service/
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alarts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for Ballerina restful service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

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

- Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
- Run the Prometheus docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `asynchronous-invocation/guide`
```
   $ nohup ballerina run stock_quote_summary_service/ &>> ballerina.log&
```
   NOTE: This will write the console log to the `ballerina.log` file in the `asynchronous-invocation/guide` directory

- Start Elasticsearch using the following command

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```

- Configure logstash to format the ballerina logs

i) Create a file named `logstash.conf` with the following content
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

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
  
 - Configure filebeat to ship the ballerina logs
    
i) Create a file named `filebeat.yml` with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of filebeat.yml file using `$chmod go-w filebeat.yml` 

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
```
$ docker run -v {SAMPLE_ROOT}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/stock_quote_summary_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```
