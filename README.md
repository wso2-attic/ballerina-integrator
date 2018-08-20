# messaging-with-activemq

This Guide will illustrate how to configure ballerina services as a JMS producer (one way messaging, aka fire and forget mode) and JMS consumer with ActiveMQ message broker.

Let's consider a real-world scenario where online order management system. Clients can place their orders, then Order accepting ballerina service will place that orders into a message broker queue, then Order dispatcher ballerina service will route them to a difference queues by considering the message content( it will check retail order or wholesale order), then respective ballerina services will consume the messages from each queue.


![alt text](https://github.com/tdkmalan/messaging-with-activemq/blob/master/JMS_bal_Service.png)


The following are the sections available in this guide.

- What you'll build
- Prerequisites
- Implementation
- Testing
- Deployment
- Observability

# Prerequisites

- Ballerina Distribution
- Apache ActiveMQ 5.12.0

**Note -**
After installing the JMS broker, copy its .jar files into the <BALLERINA_HOME>/bre/lib folder
For ActiveMQ 5.12.0: Copy activemq-client-5.12.0.jar, geronimo-j2ee-management_1.1_spec-1.0.1.jar and hawtbuf-1.11.jar

A Text Editor or an IDE


# Implementation
If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping "Implementation" section.

# Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
messaging-with-activemq
 └── guide
      ├── order_accepting_service
      │    ├── order_accepting_service.bal
      │    └── tests
      │         └── order_accepting_service_test.bal
      │ 
      │── order_dispatcher_service
      │    └── order_dispatcher_service.bal
      │   	
      └── retail_order_process_service
      │    └── retail_order_process_service.bal
      │ 
      └── retail_order_process_service
	       └── wholesale_order_process_service.bal	
```
     
- Create the above directories in your local machine and also create empty .bal files.
- Then open the terminal and navigate to messaging-with-activemq/guide and run Ballerina project initializing toolkit.

```ballerina
  $ ballerina init
```
# Developing the service

Let's get start with the implementation of the "order_accepting_service.bal", which acts as a http endpoint which accept request from client and publish messages to a JMS destination. "order_dispatcher_service.bal" process the each message recieve to the Order_Queue and route orders to the destinations queues by considering their message content. "retail_order_process_service.bal" and "wholesale_order_process_service.bal" are listner services for the retail_Queue and Wholesale_Queue.

**order_accepting_service.bal**
```ballerina
import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerinax/docker;

// Type definition for a order
type Order record {
    string customerID;
    string productID;
    string quantity;
    string orderType;
};

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer {
    session: jmsSession,
    queueName: "Order_Queue"
};

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "order_accepting_service.bal",
//    tag: "v1.0"
//}

//@docker:CopyFiles {
//    files: [{ source: "/home/krishan/Servers/apache-activemq-5.12.0/lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar",
//        target: "/ballerina/runtime/bre/lib" }, { source:
//    "/home/krishan/Servers/apache-activemq-5.12.0/lib/activemq-client-5.12.0.jar",
//        target: "/ballerina/runtime/bre/lib" }] }

//@docker:Expose {}
endpoint http:Listener listener {
    port: 9090
};

// Order Accepting Service, which allows users to place order online
@http:ServiceConfig { basePath: "/placeOrder" }
service<http:Service> orderAcceptingService bind listener {
    // Resource that allows users to place an order 
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    place(endpoint caller, http:Request request) {
        http:Response response;
        Order newOrder;
        json reqPayload;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
                _ = caller->respond(response);
                done;
            }
        }

        json customerID = reqPayload.customerID;
        json productID = reqPayload.productID;
        json quantity = reqPayload.quantity;
        json orderType = reqPayload.orderType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (customerID == null || productID == null || quantity == null || orderType == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = caller->respond(response);
            done;
        }

        // Order details
        newOrder.customerID = customerID.toString();
        newOrder.productID = productID.toString();
        newOrder.quantity = quantity.toString();
        newOrder.orderType = orderType.toString();

        json responseMessage;
        var orderDetails = check <json>newOrder;
        // Create a JMS message
        jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails.toString());
        // Send the message to the JMS queue
        _ = jmsProducer->send(queueMessage);
        // Construct a success message for the response
        responseMessage = { "Message": "Your order is successfully placed" };
        log:printInfo("New order added to the JMS Queue; customerID: '" + newOrder.customerID +
                "', productID: '" + newOrder.productID + "';");

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller->respond(response);
    }
}
```
**order_dispatcher_service.bal**

```ballerina
import ballerina/log;
import ballerina/jms;
import ballerina/io;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session: jmsSession,
    queueName: "Order_Queue"
};

// Initialize a retail queue sender using the created session
endpoint jms:QueueSender jmsProducerRetail {
    session: jmsSession,
    queueName: "Retail_Queue"
};

// Initialize a wholesale queue sender using the created session
endpoint jms:QueueSender jmsProducerWholesale {
    session: jmsSession,
    queueName: "Wholesale_Queue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDispatcherService bind jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    onMessage(endpoint consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = check message.getTextMessageContent();
        log:printInfo("validating  Details: " + orderDetails);
        //Converting String content to JSON
        io:StringReader reader = new io:StringReader(orderDetails);
        json result = check reader.readJson();
        var closeResult = reader.close();
        //Retrieving JSON attribute "OrderType" value
        json orderType = result.orderType;
        //filtering and routing messages using message orderType
        if (orderType.toString() == "retail"){
            // Create a JMS message
            jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails);
            // Send the message to the Retail JMS queue
            _ = jmsProducerRetail->send(queueMessage);
            log:printInfo("New Retail order added to the Retail JMS Queue");
        } else if (orderType.toString() == "wholesale"){
            // Create a JMS message
            jms:Message queueMessage = check jmsSession.createTextMessage(orderDetails);
            // Send the message to the Wolesale JMS queue
            _ = jmsProducerWholesale->send(queueMessage);
            log:printInfo("New Wholesale order added to the Wholesale JMS Queue");
        } else {
            //ignoring invalid orderTypes  
            log:printInfo("No any valid order type recieved, ignoring the message, order type recieved - " + orderType.
                    toString());
        }
    }
}
```
**retail_order_process_service.bal**

```ballerina
import ballerina/log;
import ballerina/jms;
import ballerina/io;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a retail queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session: jmsSession,
    queueName: "Retail_Queue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDispatcherService bind jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    onMessage(endpoint consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = check message.getTextMessageContent();
        //Convert String Payload to the JSON
        io:StringReader reader = new io:StringReader(orderDetails);
        json result = check reader.readJson();
        var closeResult = reader.close();
        log:printInfo("New retail order has been processed successfully; Order ID: '" + result.customerID.toString() +
                "', Product ID: '" + result.productID.toString() + "', Quantity: '" + result.quantity.toString() + "';");

    }
}
```
**wholesale_order_process_service.bal**

```ballerina
import ballerina/log;
import ballerina/jms;
import ballerina/io;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a retail queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session: jmsSession,
    queueName: "Wholesale_Queue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDispatcherService bind jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    onMessage(endpoint consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = check message.getTextMessageContent();
        //Convert String Payload to the JSON
        io:StringReader reader = new io:StringReader(orderDetails);
        json result = check reader.readJson();
        var closeResult = reader.close();
        log:printInfo("New wholesale order has been processed successfully; Order ID: '" + result.customerID.toString() +
                "', Product ID: '" + result.productID.toString() + "', Quantity: '" + result.quantity.toString() + "';");

    }
}

```

# Testing

**innvoking the service**

- First, start the Apache ActiveMQ server by entering the following command in a terminal from <ActiveMQ_BIN_DIRECTORY>.

```
   $ ./activemq start
```
- run following commands in seperate terminals.
 
```ballerina
   $ ballerina run order_accepting_service.bal
   $ ballerina run order_dispatcher_service.bal
   $ ballerina run retail_order_process_service.bal
   $ ballerina run wholesale_order_process_service.bal
```
- You can use below requests to simulate retail and wholesale order placing.

```
curl -d '{"customerID":"C001","productID":"P001","quantity":"4","orderType":"retail"}' -H "Content-Type: application/json" -X POST http://localhost:9090/placeOrder/place
 
curl -d '{"customerID":"C002","productID":"P002","quantity":"40000","orderType":"wholesale"}' -H "Content-Type: application/json" -X POST http://localhost:9090/placeOrder/place
 
```
# Writing unit tests

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. When writing the test functions the below convention should be followed.

Test functions should be annotated with @test:Config. See the below example.

```ballerina
   @test:Config
   function testResourcePickup() {
```
# Deployment

Once you are done with the development, you can deploy the services using any of the methods that we listed below.

**Deploying locally**

As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to  messaging-with-activemq/guide and run the following command.
```ballerina
   $ ballerina build
```
Once the .balx files are created inside the target folder, you can run them using the following command.

```ballerina
   $ ballerina run <Exec_Archive_File_Name>
```
The successful execution of a service will show us something similar to the following output.

```
ballerina: initiating service(s) in 'order_accepting_service.balx'
ballerina: initiating service(s) in 'order_dispatcher_service.balx'
ballerina: initiating service(s) in 'retail_order_process_service.balx'
ballerina: initiating service(s) in 'wholesale_order_process_service.balx'
```

**Deploying on Docker**

You can run the service that we developed above as a docker container. As Ballerina platform includes Ballerina_Docker_Extension, which offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. Since this guide requires ActiveMQ as a prerequisite, you need a couple of more steps to configure it in docker container.

Please follow bleow steps.

- pull the ActiveMQ 5.12.0 docker image.

```
docker pull consol/activemq-5.12
```

- Launch the docker image

```
docker run -d --name='activemq' -it --rm -P consol/activemq-5.12:latest
```
- then execte ``` docker ps ``` command and check ActiveMQ container is up and ruuning.

```
f80fa55fe8c9        consol/activemq-5.12:latest   "/bin/sh -c '/opt/ap…"   8 hours ago         Up 8 hours          0.0.0.0:32779->1883/tcp, 0.0.0.0:32778->5672/tcp, 0.0.0.0:32777->8161/tcp, 0.0.0.0:32776->61613/tcp, 0.0.0.0:32775->61614/tcp, 0.0.0.0:32774->61616/tcp   activemq
```
Now let's see how we can deploy the order_acepting_service we developed above on docker. We need to import ballerinax/docker and use the annotation @docker:Config as shown below to enable docker image generation during the build time.


**order_acepting_service**

```ballerina
import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerinax/docker;   

// Type definition for a order
type Order record {
    string customerID;
    string productID;
    string quantity;
    string orderType;
};

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://172.17.0.2:61616" 
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer {
    session:jmsSession,
    queueName:"Order_Queue"
};

@docker:Config {
    registry:"ballerina.guides.io",
    name:"order_accepting_service.bal",
    tag:"v1.0"
}

@docker:CopyFiles {
    files:[{source:<path_to_JMS_broker_jars>,
            target:"/ballerina/runtime/bre/lib"}]
}

@docker:Expose{}
endpoint http:Listener listener {
    port:9090
};

// Order Accepting Service, which allows users to place order online
@http:ServiceConfig {basePath:"/placeOrder"}
service<http:Service> orderAcceptingService bind listener {
    // Resource that allows users to place an order 
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    place(endpoint caller, http:Request request) {
        http:Response response;
        Order newOrder;
```

- You may configure other services the same way as above i.e order_dispatcher_service.bal, wholesale_order_process_service.bal, retail_order_process_service.bal what you may need to change @docker:Config names to the respective services

- @docker:Config annotation is used to provide the basic docker image configurations for the sample. @docker:CopyFiles is used to copy the JMS broker jar files into the ballerina bre/lib folder. You can provide multiple files as an array to field files of CopyFiles docker annotation. @docker:Expose {} is used to expose the port.

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to messaging-with-activemq/guide and run the following command.

```ballerina

ballerina build

```
Then run below commands to start docker containers

```
docker run -d -p 9090:9090 ballerina.guides.io/order_accepting_service.bal:v1.0
docker run -d  ballerina.guides.io/order_dispatcher_service.bal:v1.0
docker run -d  ballerina.guides.io/wholesale_order_process_service.bal:v1.0
docker run -d  ballerina.guides.io/retail_order_process_service.bal:v1.0
```

- Verify docker container is running with the use of $ docker ps. The status of the docker container should be shown as 'Up'.

- You can access the service using the same curl commands that we've used above.

```
curl -d '{"customerID":"C001","productID":"P001","quantity":"4","orderType":"retail"}' -H "Content-Type: application/json" -X POST http://localhost:9090/placeOrder/place
```

# Observability

Ballerina is by default observable. Meaning you can easily observe your services, resources, etc. However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to ballerina.conf file in messaging-with-activemq/guide/.

```
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```
NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations default values are load as the other configuration parameters of metrics and tracing.

# Tracing

- You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use Jaeger as the distributed tracing system. Follow the following steps to use tracing with Ballerina.

- You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in ballerina.conf as described above.
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

```
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 p14268:14268 jaegertracing/all-in-one:latest
```
- Navigate to messaging-with-activemq/guide and run the order_accepting_service using following command

```
   $ ballerina run order_accepting_service/
```
- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

# Metrics

Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool. Follow the below steps to set up Prometheus and view metrics for order_accepting_service service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in ballerina.conf as described under Observability section.
```
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

- Create a file prometheus.yml inside /tmp/ location. Add the below configurations to the prometheus.yml file.

```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```
NOTE : Replace 172.17.0.1 if your local docker IP differs from 172.17.0.1

- Run the Prometheus docker image using the following command

```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
- You can access Prometheus at the following URL
```
   http://localhost:19090/
```
NOTE: Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI

- http_requests_total
- http_response_time

# Logging

Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from messaging-with-activemq/guide
```
   $ nohup ballerina run order_accepting_service/ &>> ballerina.log&
   ```
NOTE: This will write the console log to the ballerina.log file in the inter-microservice-communicaiton/guide directory

- Start Elasticsearch using the following command

```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```
NOTE: Linux users might need to run sudo sysctl -w vm.max_map_count=262144 to increase vm.max_map_count

- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```
- Configure logstash to format the ballerina logs
i) Create a file named ``logstash.conf`` with the following content
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
ii) Save the above logstash.conf inside a directory named as {SAMPLE_ROOT}\pipeline

iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name

```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
Configure filebeat to ship the ballerina logs
i) Create a file named filebeat.yml with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of filebeat.yml file using $chmod go-w filebeat.yml

ii) Save the above filebeat.yml inside a directory named as {SAMPLE_ROOT}\filebeat

iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/order_accepting_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```

- Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```
