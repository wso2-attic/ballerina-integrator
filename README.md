[![Build Status](https://travis-ci.org/ballerina-guides/pass-through-messaging.svg?branch=master)](https://travis-ci.org/ballerina-guides/pass-through-messaging)

# Pass-through messaging
There are different ways of messaging methods in SOA (Service Oriented Architecture). In this guide, we are focusing on pass-through Messaging between services using an example scenario.

> This guide describes implementing pass-through messaging using Ballerina programming language as simple steps.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build

There are different ways of messaging between services such as pass-through messaging, content-based routing of messages, header-based routing of messages, and scatter-gather messaging. There is a delay in messaging while processing an incoming message in all messaging methods excluding pass-through messaging. When routing the message without processing/inspecting the message payload, the most efficient way is the pass-through messaging. Here are some differences between conventional message processing vs pass-through messaging.

![alt text](images/pass-through-messaging-1.svg	)

Conventional message processing methods include a message processor for processing messages, but pass-through messaging skipped the message processor. It thereby saves the processing time and power and is more efficient when compared to other types.

Now let's understand the scenario described here. The owner needs to expand the business, so he makes online shop that is connected to the local shop, to expand the business. When you connect to the online shop, it will automatically be redirected to the local shop without any latency. To do so, the pass-through messaging method is used.

![alt text](images/pass-through-messaging-2.svg	)

The two shops are implemented as two separate services named as 'OnlineShopping' and 'LocalShop'. When a user makes a call to 'OnlineShopping' using an HTTP request, the request is redirected to the 'LocalShop' service without processing the incoming request. Also the response from the 'LocalShop' is not be processed in 'OnlineShopping'. If it processes the incoming request or response from the 'LocalShop', it will no longer be a pass-through messaging method. 

So, messaging between 'OnlineShopping' and 'LocalShop' services act as pass-through messaging. The 'LocalShop' service processes the incoming request method such as 'GET' and 'POST'. Then it calls the back-end service, which will give the "Welcome to Local Shop! Please put your order here....." message. So messaging in the 'LocalShop' service is not a pass-through messaging service.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you are well aware of the implementation, you can directly clone the GitHub repository to your own device. Using that, you can skip the "Implementation" section and move straight to the "Testing" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
 └── guide
     ├── passthrough
     │   └── passthrough.bal
     │  
     └── tests
         └── passthrough_test.bal

```

Create the above directories in your local machine and also create empty `.bal` files.

Open the terminal and navigate to `Simple-pass-through-messaging-ballerina-/guide` and run the Ballerina project initializing toolkit.

```bash
   $ ballerina init
```

### Developing the service

To implement the scenario, let's start by implementing the passthrough.bal file, which is the main file in the implementation. Refer to the code attached below. Inline comments are added for better understanding.

##### passthrough.bal

```ballerina

import ballerina/http;
import ballerina/log;
endpoint http:Listener OnlineShoppingEP {
    port:9090
};
endpoint http:Listener LocalShopEP {
    port:9091
};
//Define endpoint for the local shop as online shop link.
endpoint http:Client clientEP {
    url: "http://localhost:9091/LocalShop"
};

service<http:Service> OnlineShopping bind OnlineShoppingEP {
    // This service is implemented as a passthrough service. So it allows all HTTP methods. So methods are not specified.
    @http:ResourceConfig {
        path: "/"
    }

    passthrough(endpoint caller, http:Request req) {
        // Set log message as "the request will be directed to another service" in the pass-through method.
        log:printInfo("You will be redirected to Local Shop  .......");
        // 'Forward()' is used to call the backend endpoint created above as pass-through method. In forward function,
        // it used the same HTTP method, which is used to invoke the primary service.
        // The `forward()` function returns the response from the backend if there are no errors.
        var clientResponse = clientEP->forward("/", req);
        // In order to detect the errors in the return output of 'forward()', 'match' is used to catch those kind of errors.
        match clientResponse {
            // Returned response is directed to the outbound endpoint.
            http:Response res => {
                caller->respond(res)
                // If response contains errors, give the error message
                but { error e =>
                log:printError("Error sending response", err = e) };
            }
            // If there was an error, the 500 error response is constructed and sent back to the client.
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                caller->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}

//Sample Local Shop service.
service<http:Service> LocalShop bind LocalShopEP {
    //The LocalShop only accepts requests made using the specified HTTP methods.
    @http:ResourceConfig {
        methods: ["POST", "GET"],
        path: "/"
    }
    helloResource(endpoint caller, http:Request req) {
        //Set log to view the status to know that the passthrough was successfull.
        log:printInfo("Now You are connected to Local shop  .......");
        // Make the response for the request.
        http:Response res = new;
        res.setPayload("Welcome to Local Shop! Please put your order here.....");
        // Pass the response to the caller.
        caller->respond(res)
        // Catch the errors that occur while passing the response.
        but { error e =>
        log:printError("Error sending response", err = e) };
    }
}
```

## Testing 

### Invoking the service

Navigate to `pass-through` and run the following command in the command line to start `passthrough.bal`.

```bash
   $ ballerina run passthrough.bal
```
   
Send a request to the online shopping service.

```bash

 $ curl -v http://localhost:9090/OnlineShopping -X GET

```
#### Output

When connecting to the online shopping, the output will be "Welcome to Local Shop! Please put your order here....." from the local shop.

```bash
< HTTP/1.1 200 OK
< content-type: text/plain
< date: Sat, 23 Jun 2018 05:45:17 +0530
< server: ballerina/0.970.1
< content-length: 54
< 
* Connection #0 to host localhost left intact
Welcome to Local Shop! Please put your order here.....
```

To identify the message flow inside the services, there will be INFO in the notification channel.

```bash
2018-06-23 05:45:27,849 INFO  [passthrough] - You will be redirected to Local Shop  ....... 
2018-06-23 05:45:27,864 INFO  [passthrough] - Now You are connected to Local shop  ....... 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions, the below convention should be followed.

Test functions should be annotated with `@test:Config`. See the below example.

```ballerina
   @test:Config
   function testFunc() {
   }
```

This guide contains unit test case for 'LKSubOffice' service and 'UKSubOffice' service in [passthrough_test.bal](https://github.com/sanethmaduranga/Simple-pass-through-messaging-ballerina-/blob/master/guide/tests/passthrough_test.bal) file.

To run the unit tests, navigate to `Simple-pass-through-messaging-ballerina-/guide/` and run the following command. 

```bash
   $ ballerina test
```

## Deployment

After the development process, you can deploy the services using below methods by selecting as you wish.

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that you developed above. Navigate to `Pass-through-messaging-ballerina-/guide` and run the following command.

```bash
   $ ballerina build
```

Once the .balx files are created inside the target folder, you can run them using the following command. 

```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

The successful execution of a service will show us something similar to the following output.

```
   ballerina: initiating service(s) in 'target/passthrough.balx'
   
```

### Deploying on Docker

You can run the service that we developed above as a Docker container.

As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running Ballerina programs on containers, you just need to put the corresponding Docker annotations on your service code.

In our `passthrough`, we need to import  `ballerinax/docker` and use the annotation `@docker:Config,@docker:Expose` as shown below to enable Docker image generation during the build time. 

##### passthrough.bal

```ballerina
import ballerina/http;
import ballerina/log;
import ballerinax/docker;

@docker:Expose {}
endpoint http:Listener OnlineShoppingEP {
    port:9090
};
@docker:Expose {}
endpoint http:Listener LocalShopEP {
    port:9091
};
//Define end-point for the local shop as online shop link
endpoint http:Client clientEP {
    url: "http://localhost:9091/LocalShop"
};
@docker:Config {
    registry:"ballerina.guides.io",
    name:"passthrough",
    tag:"v1.0"
}

service<http:Service> OnlineShopping bind OnlineShoppingEP {
.
.
.
}
service<http:Service> LocalShop bind LocalShopEP {
.
.
}
``` 

Now you can build a Ballerina executable archive (.balx) of the service that you developed above using the following command. This also creates the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `Simple-pass-through-messaging-ballerina-/guide` and run the following command.  
  
```
   $ballerina build passthrough
  
  
   Run following command to start docker container:
   docker run -d -p 9090:9090 -p 9091:9091 ballerina.guides.io/passthrough:v1.0

```

Once you successfully build the Docker image, you can run it with the `docker run` command that is shown in the previous step.  

```bash
   $ docker run -d -p 9090:9090 -p 9091:9091 ballerina.guides.io/passthrough:v1.0
```

You can run the Docker image with the flag `-p <host_port>:<container_port>` so that we use the host port 9090 and the container port 9090. Therefore, you can access the service through the host port. 

Verify if the Docker container is running with the use of `$ docker ps`. The status of the Docker container should be shown as 'Up'. 

You can access 'OnlineShopping' service, using the same cURL commands that you've used above. 

```bash
    curl -v http://localhost:9090/OnlineShopping -X GET
```

### Deploying on Kubernetes

You can run the service that you developed above on Kubernetes. The Ballerina language offers native support for running Ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of Docker images. So you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

Let's now see how to deploy `passthrough` on Kubernetes. First, you need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable Kubernetes deployment for the service you developed above. 

##### passthrough.bal

```ballerina
import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"passthrough",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"OnlineShopping"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"LocalShop"
}
@kubernetes:Deployment {
    image: "ballerina.guides.io/passthrough:v1.0",
    name: "ballerina-guides-pass-through-messaging"
}
endpoint http:Listener OnlineShoppingEP {
    port:9090
};
endpoint http:Listener LocalShopEP {
    port:9091
};

//Define end-point for the local shop as online shop link
endpoint http:Client clientEP {
    url: "http://localhost:9091/LocalShop"
};
service<http:Service> OnlineShopping bind OnlineShoppingEP {
.
.
.
}
service<http:Service> LocalShop bind LocalShopEP {
.
.
}
``` 

Here we have used `@kubernetes:Deployment` to specify the Docker image name, which is created as part of building this service. 

You have also specified `@kubernetes:Service` so that it will create a Kubernetes service, which exposes the Ballerina service that is running on a Pod.  

In addition, you have used `@kubernetes:Ingress`, which is the external interface to access your service (with path `/` and hostname `ballerina.guides.io`)

Now you can build a Ballerina executable archive (.balx) of the service that you developed above using the following command. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build passthrough

   Run following command to deploy kubernetes artifacts: 
   kubectl apply -f /home/saneth/Documents/ballerina/sample_pass-through/guide/target/kubernetes/

```

You can verify that the Docker image that you specified in `@kubernetes:Deployment` is created by using the `docker images` command. 

Also, the Kubernetes artifacts related to your service will be generated under `/home/saneth/Documents/ballerina/sample_pass-through/guide/target/kubernetes/`. 

Now you can create the Kubernetes deployment using:

```bash
   $ kubectl apply -f /home/saneth/Documents/ballerina/sample_pass-through/guide/target/kubernetes/ 
 
   deployment.extensions "ballerina-guides-pass-through-messaging" created
   ingress.extensions "passthrough" created
   service "passthrough" created
```

You can verify that the Kubernetes deployment, service, and ingress are running properly, by using following Kubernetes commands. 

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

If everything is successfully deployed, you can invoke the service either via Node port or ingress. The cURL request for the 'OnlineShopping' service is mentioned below to get the results.
 
Node Port:

```bash
   curl -v http://localhost:<Node_Port>/OnlineShopping -X GET  
```

Ingress:

Add `/etc/hosts` entry to match hostname. 

``` 
   127.0.0.1 ballerina.guides.io
```

Access the service.

```bash
   curl -v http://ballerina.guides.io/OnlineShopping -X GET
```


## Observability 
Ballerina is by default observable. This means you can easily observe your services, resources, etc. However, observability is disabled by default via configuration. Observability can be enabled by adding the following configurations to the `ballerina.conf` file in `Simple-pass-through-messaging-ballerina-/guide/`.

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

You can monitor Ballerina services using inbuilt tracing capabilities of Ballerina. Let's use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.

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

Run the Jaeger Docker image using the following command.

```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 -p14268:14268 jaegertracing/all-in-one:latest
```

Navigate to `Simple-pass-through-messaging-ballerina-/guide` and run the `passthrough` using following command 

```
   $ ballerina run passthrough/
```

Observe the tracing using Jaeger UI using the following URL.

```
   http://localhost:16686
```

### Metrics

Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool. Follow the steps below to set up Prometheus and view metrics for 'passthrough'.

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

Create a file `prometheus.yml` inside the `/tmp/` location. Add the below configurations to the `prometheus.yml` file.

```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

> **NOTE**: Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`
   
Run the Prometheus docker image using the following command

```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
You can access Prometheus at the following URL.

```
   http://localhost:19090/
```

> **NOTE**: Ballerina will by default have the following metrics for HTTP server connector. You can enter the following expression in Prometheus UI.
>    -  http_requests_total
>    -  http_response_time

### Logging

Ballerina has a log package for logging to the console. You can import `ballerina/log` package and start logging. The following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

Start the Ballerina service with the following command from `Simple-pass-through-messaging-ballerina-/guide`

```
   $ nohup ballerina run trip-management/ &>> ballerina.log&
```

> **NOTE**: This writes the console log to the `ballerina.log` file in the `Simple-pass-through-messaging-ballerina-/guide` directory.

Start Elasticsearch using the following command.

```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

> **NOTE**: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count`.
   
Start Kibana plugin for data visualization with Elasticsearch.

```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
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
     
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name.
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
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

> **NOTE**: Modify the ownership of `filebeat.yml` file using `$chmod go-w filebeat.yml`.

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name.
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/passthrough/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
Access Kibana to visualize the logs using the following URL.

```
   http://localhost:5601 
```

