# Message Construction Patterns

Message construction patterns describe the various forms of message content that travel across messaging systems. Message construction involves the architectural patterns of various constructs, functions, and activities involved in creating and transforming a message between applications.

Java Message Service (JMS) is a messaging standard that is used to send messages between two or more clients. JMS supports two models for messaging as follows:
- Point-to-point model
- Publish/subscribe model
A JMS synchronous invocation takes place when a JMS producer receives a response to a JMS request produced by it when invoked.

This guide described how to use messaging implemented in JMS and also describes how to implement request-reply where a requestor application sends a request, a replier application receives the request and returns a reply, and finally the requestor application receives the reply. 

> Let’s take a look at a sample real world scenario to understand how to use Ballerina for message construction with JMS queues using a message broker.

The high level sections of this guide are as follows:

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understand how to use JMS queues for messaging, let’s consider a mobile phone store that allows you to order mobile phones and also does home delivery. 
The mobile phone store should have the following services:
- `phone_store_service` : The message endpoint that sends a request message and waits to receive a response.
- `phone_order_delivery_service` : A message endpoint that waits to receive the request message, and when received, it sends a  response.
When a valid order is placed, the `phone_store_service` adds the order to a JMS queue named `OrderQueue`. Here, the `phone_store_service` acts as the message requestor, and the `phone_order_delivery_service` acts as the message replier. The `phone_order_delivery_service`gets the order details whenever the queue is populated, and forwards the details to the `DeliveryQueue` via the `phone_order_delivery_service`.

As this use case is based on message construction patterns, the scenario uses request-reply with a pair of Point-to-Point Channels. The request is a command message, whereas the reply is a document message that contains either the return value of the function or an exception. 

The following diagram illustrates the scenario:

![alt text](/resources/message_construction_patterns.svg)


For the scenario In this guide, you will use `Apache ActiveMQ` as the JMS broker. You will also use Ballerina JMS connector to connect Ballerina with the JMS message broker. When you use the Ballerina JMS connector, Ballerina can act as a JMS message consumer as well as a JMS message producer.

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After you install ActiveMQ, copy the .jar files from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
  * If you use ActiveMQ version 5.15.4, you only have to copy `activemq-client-5.15.4.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar` and `hawtbuf-1.11.jar` from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.

### Optional Requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from git and skip the implementation instructions.
   

### Creating the project structure

Ballerina is an integration language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:
```
message_construction_patterns
 └── guide
      ├── phone_store_service
      │    ├── phone_store_service.bal
      │    └── tests
      │         └── phone_store_service.bal
      └── phone_order_delivery_service
           ├──phone_order_delivery_service.bal
           └── tests
                └── phone_order_delivery_service_test.bal

```

- Create the above directories in your local machine and initialize a Ballerina project.

- Then open the terminal and navigate to `message_construction_patterns/guide` and run the Ballerina project initializing toolkit.
```bash
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Developing the service

First, you need to implement the `phone_store_service` to act as the message requestor. 
Take a look at the sample code below to understand how to implement the service. 

##### phone_store_service.bal

```ballerina
import ballerina/http;
import ballerina/jms;
import ballerina/log;

type PhoneOrder record {
    string customerName?;
    string address?;
    string contactNumber?;
    string orderedPhoneName?;
};

// Global variable containing all the available phones.
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// Initialize a JMS connection with the provider.
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use.
// 'Apache ActiveMQ' has been used as the message broker in this example.
jms:Connection orderQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session orderQueueJmsSessionSend = new(orderQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session.
jms:QueueSender jmsProducerOrderQueue = new(orderQueueJmsSessionSend, queueName = "OrderQueue");

// Service endpoint.
listener http:Listener httpListener = new(9090);

http:Request backendreq = new;

// Phone store service, which allows users to order phones online for delivery.
@http:ServiceConfig {
    basePath: "/phonestore"
}
service phoneStoreService on httpListener {
    // Resource that allows users to place an order for a phone.
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        backendreq = untaint request;
        http:Response response = new;
        PhoneOrder newOrder = {};
        json requestPayload = {};

        var payload = request.getJsonPayload();
        // Try parsing the JSON payload from the request.
        if (payload is json) {
            // Valid JSON payload.
            requestPayload = payload;
        } else {
            // NOT a valid JSON payload.
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            checkpanic caller->respond(response);
        }

        json name = requestPayload.Name;
        json address = requestPayload.Address;
        json contact = requestPayload.ContactNumber;
        json phoneName = requestPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            checkpanic caller->respond(response);
        }

        // Order details.
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // Boolean variable to track the availability of a requested phone.
        boolean isPhoneAvailable = false;
        // Check whether the requested phone available.
        foreach var phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'.
        if (isPhoneAvailable) {
            var phoneOrderDetails = json.convert(newOrder);

            if(phoneOrderDetails is json) {
                // Create a JMS message.
                var queueMessage = orderQueueJmsSessionSend.createTextMessage(phoneOrderDetails.toString());

                if (queueMessage is jms:Message) {
                    log:printInfo("order will be added to the order  Queue; CustomerName: '" + newOrder.customerName +
                            "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");
                    // Send the message to the JMS queue.
                    checkpanic jmsProducerOrderQueue->send(queueMessage);

                    // Construct a success message for the response.
                    responseMessage = { "Message":
                    "Your order was successfully placed. Ordered phone will be delivered soon" };
                } else {
                    responseMessage = { "Message": "Error while creating the message" };
                }
            } else {
                responseMessage = { "Message": "Invalid order delivery details" };
            }
        }
        else {
            // If phone is not available, construct a proper response message to notify user.
            responseMessage = { "Message": "Requested phone not available" };
        }

        // Send response to the user.
        response.setJsonPayload(responseMessage);
        checkpanic caller->respond(response);
    }
    // Resource that allows users to get a list of all the available phones.
    @http:ResourceConfig { methods: ["GET"], produces: ["application/json"] }
    resource function getPhoneList(http:Caller httpClient, http:Request request) {
        http:Response response = new;
        // Send json array 'phoneInventory' as the response, which contains all the available phones.
        response.setJsonPayload(phoneInventory);
        checkpanic httpClient->respond(response);
    }
}

jms:Connection orderQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session orderQueueJmsSessionReceive = new(orderQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session.
listener jms:QueueReceiver jmsConsumerOrderQueue = new(orderQueueJmsSessionReceive, queueName = "OrderQueue");

// JMS service that consumes messages from the JMS queue.
// Bind the created consumer to the listener service.
service orderDeliverySystem on jmsConsumerOrderQueue {

    // Triggered whenever an order is added to the 'OrderQueue'.
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New order successfilly received from the Order Queue");

        // Retrieve the string payload using native function.
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Order Details: " + stringPayload);
        }

        // Send order queue details to delivery queue.
        http:Request enrichedreq = backendreq;
        var clientResponse = phoneOrderDeliveryServiceEP->forward("/", enrichedreq);
        if (clientResponse is http:Response) {
            log:printInfo("Order details were sent to phone_order_delivery_service.");
        } else {
            log:printError("Order details were not sent to phone_order_delivery_service.");
        }
    }
}
http:Client phoneOrderDeliveryServiceEP = new("http://localhost:9091/deliveryDetails/sendDelivery");


```
Next, implement the `order_delivery_service.bal` to act as the message replier. 
Take a look at the sample code below to understand how to implement the service.

#### phone_order_delivery_service.bal

```ballerina
import ballerina/http;
import ballerina/jms;
import ballerina/log;

type PhoneDeliver record {
    string customerName?;
    string address?;
    string contactNumber?;
    string deliveryPhoneName?;
};

json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

jms:Connection DeliveryQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session DeliveryQueueJmsSessionSend = new(DeliveryQueueJmsConnectionSend,
    { acknowledgementMode: "AUTO_ACKNOWLEDGE" });

// Initialize a queue sender using the created session.
jms:QueueSender jmsProducerDeliveryQueue = new(DeliveryQueueJmsSessionSend, queueName = "DeliveryQueue");


// Service endpoint.
listener http:Listener deliveryEP = new(9091);

@http:ServiceConfig {
    basePath: "/deliveryDetails"
}
// Phone store service, which allows users to order phones online for delivery.
service phoneOrderDeliveryService on deliveryEP {

    // Resource that allows users to place an order for a phone.
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function sendDelivery(http:Caller caller, http:Request request) {
        http:Response response = new;
        PhoneDeliver newDeliver = {};
        json requestPayload = {};

        log:printInfo("Received order details from the phone store service");

        // Try parsing the JSON payload from the request.
        var payload = request.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload.
            requestPayload = payload;
        } else {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            checkpanic caller->respond(response);
        }

        json name = requestPayload.Name;
        json address = requestPayload.Address;
        json contact = requestPayload.ContactNumber;
        json phoneName = requestPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response.
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            checkpanic caller-> respond(response);
        }

        // Order details.
        newDeliver.customerName = name.toString();
        newDeliver.address = address.toString();
        newDeliver.contactNumber = contact.toString();
        newDeliver.deliveryPhoneName = phoneName.toString();

        // Boolean variable to track the availability of a requested phone.
        boolean isPhoneAvailable = false;

        // Check the availability of the requested phone.
        foreach var phone in phoneInventory {
            if (newDeliver.deliveryPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage = {};

        // If the requested phone is available, then add the order to the 'OrderQueue'.
        if (isPhoneAvailable) {
            var phoneDeliverDetails = json.convert(newDeliver);
            // Create a JMS message.
            if (phoneDeliverDetails is json) {
                var queueMessage = DeliveryQueueJmsSessionSend.createTextMessage(phoneDeliverDetails.toString());
                if (queueMessage is jms:Message) {
                    log:printInfo("Order delivery details added to the delivery queue'; CustomerName: '" + newDeliver.
                            customerName +
                            "', OrderedPhone: '" + newDeliver.deliveryPhoneName + "';");
                    // Send the message to the JMS queue.
                    checkpanic jmsProducerDeliveryQueue-> send(queueMessage);

                    // Construct a success message for the response.
                    responseMessage =
                    { "Message": "Your order was successfully placed. Ordered phone will be delivered soon" };
                } else {
                    responseMessage =
                    { "Message": "Failed to place the order, Error while creating the message" };
                }
            } else {
                responseMessage =
                { "Message": "Failed to place the order, Invalid phone delivery details" };
            }
        }
        else {
            // If phone is not available, construct a proper response message to notify user.
            responseMessage = { "Message": "Requested phone not available" };
        }
        // Send response to the user
        response.setJsonPayload(responseMessage);
        checkpanic caller->respond(response);
    }
}
jms:Connection DeliveryQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session DeliveryQueueJmsSessionReceive = new(DeliveryQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session.
listener jms:QueueReceiver jmsConsumerDeliveryQueue = new(DeliveryQueueJmsSessionReceive, queueName = "DeliveryQueue");

service deliverySystem on jmsConsumerDeliveryQueue {

    // Triggered whenever an order is added to the 'OrderQueue'.
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New order successfully received from the delivery queue");

        // Retrieve the string payload using native function.
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Delivery details: " + stringPayload);
            log:printInfo("Delivery details sent to the customer successfully");
        } else {
            log:printError("Failed to retrieve the delivery details");
        }
    }
}

```


## Testing 

### Invoking the service

Follow the steps below to invoke the service.

- On a new terminal, navigate to `<AMQ_HOME>/bin`, and execute the following command to start the ActiveMQ server.

```bash
   $ ./activemq start
```

- Navigate to `eip-message-construction/guide` and run the following commands via separate terminals to start the `phone_store_service` and the `phone_order_delivery_service`.

```bash
   $ ballerina run phone_store
```

```bash
   $ ballerina run phone_order_delivery_service
```
   
- To check for available mobile phones, send a GET request to the `phone_store_service`.

```bash
   curl -v -X GET localhost:9090/phonestore/getPhoneList
```

  Once you send a GET request, the `phone_store_service` should send a response similar to the following:
```
   < HTTP/1.1 200 OK
   ["Apple:190000","Samsung:150000","Nokia:80000","HTC:40000","Huawei:100000"]
```
   
- Execute the following command to place an order:

```bash
   curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
   
```

  Once you place an order, you will see that the `phone_store_service` sends a response similar to the following:
```
   < HTTP/1.1 200 OK
   {"Message":"Your order was successfully placed. Ordered phone will be delivered soon"} 
```

  You will also see sample log messages similar to the following:
```bash

  INFO  [phone_store_service] - order will be added to the order  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_store_service] - New order successfilly received from the Order Queue 
  INFO  [phone_store_service] - Order Details: {"customerName":"John","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94718930874","orderedPhoneName":"Apple:190000"} 
  
The order details in the above log message will be sent to the phone_order_delivery_service, and the log messages on the phone_order_delivery_service will be as follows:
  
  INFO  [phone_order_delivery_service] - Order delivery details  added to the delivery  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_order_delivery_service] - New order successfilly received from the Delivery Queue 
  INFO  [phone_order_delivery_service] - Order details: {"customerName":"Bob","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94777123456","orderedPhoneName":"Apple:190000"} 
  
 Then the delivery details are sent to the customer successfully.
 
```

### Writing unit tests 

In Ballerina, unit test cases should be in the same package inside a folder named `tests`.  When writing test functions, follow the below convention:
- Annotate test functions with `@test:Config`. See the following example:

```ballerina
   @test:Config
   function testResourcePlaceOrder() {
```
  
This guide includes unit test cases for each resource available in the `phone_store_service` implemented above. 

To run the unit tests, navigate to `message_construction_patterns/guide` and execute the following command:
```bash
   $ ballerina test
```

When you run unit tests, make sure that the JMS broker is up and running.

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

To deploy locally, navigate to `message_construction_patterns/guide` and execute the following command:

```bash
   $ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed. 

- Once the .balx files are created inside the target folder, you can use the following command to run the .balx files:

```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will display an output similar to the following:
```
   ballerina: initiating service(s) in 'phone_store.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
   
   ballerina: initiating service(s) in 'phone_order_delivery_service.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9091
```
### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container.

The Ballerina language includes a [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Since `ActiveMQ` is a prerequisite in this guide, there are a few more steps you need follow to run the service you developed in a Docker container. The steps are as follows:  

- Configure `ActiveMQ` in a Docker container. You can use the following command to pull the `ActiveMQ` Docker image:

```bash
   $ docker pull webcenter/activemq
```

- Use the following command to launch the pulled image: 
```bash
   $ docker run -d --name='activemq' -it --rm -P webcenter/activemq:latest
```
This starts the `ActiveMQ` server in Docker with default configurations.

- Use the following command to check whether the `ActiveMQ` container is up and running:
```bash
   $ docker ps
```

Now, let’s see how to deploy the `phone_store_service` and `phone_order_delivery_service` on Docker. 
You need to import `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation at build time. 

##### phone_store_service.bal
```ballerina
import ballerinax/docker;

// Type definition for a phone order
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
// 'jms:Connection' definition
// 'jms:Session' definition
// 'jms:QueueSender' endpoint definition

@docker:Config {
    registry:"ballerina.guides.io",
    name:"phone_store_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
    port:9090
};

@http:ServiceConfig {basePath:"/phonestore"}
service<http:Service> phone_store_service bind listener {
``` 
Similar to the `phone_store_service.bal`, you need to define the `@docker:Config` and `@docker:Expose {}` in  `phone_order_delivery_service` for Docker deployment.

-Use the `@docker:Config` annotation to provide the basic Docker image configurations for the sample.
-Use the `@docker:Expose {}` annotation to expose the port. 

- Next, navigate to `message_construction_patterns/guide` and execute the following command to build a Ballerina executable archive (.balx) of the service that you developed above. 

```
   $ballerina build 
  
   ./target/phone_store.balx
        @docker                  - complete 3/3 

        Run following command to start docker container:
        docker run -d -p 9090:9090 ballerina.guides.io/phone_store_service:v1.0

    ./target/phone_order_delivery_service.balx
        @docker                  - complete 3/3 

        Run following command to start docker container:
        docker run -d -p 9091:9091 ballerina.guides.io/phone_order_delivery_service:v1.0

```
This also creates the corresponding Docker image using the Docker annotations that you have configured.  
  
- Once you successfully build the Docker image,  use the `` docker run`` command to run it.
   

```bash
  docker run -d -p 9090:9090 ballerina.guides.io/phone_store_service:v1.0
  docker run -d -p 9091:9091 ballerina.guides.io/phone_order_delivery_service:v1.0  
```

Here you need to run the Docker image with the `` -p <host_port>:<container_port>`` flag to use the host port 9090 and the container port 9090 so that you can access the service through the host port. 

-  Execute the `` $ docker ps`` command to verify whether the Docker container is running. The status of the Docker container should be displayed as ‘Up’. 

- If necessary you can access the service using the same curl commands that you used before.
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
```
### Deploying on Kubernetes

- If necessary, you can run the developed service on Kubernetes. The Ballerina language offers native support to run a Ballerina program on Kubernetes. 
To run a Ballerina program on Kubernetes, add the corresponding Kubernetes annotations to your 
service code. 
> NOTE: You do not need to explicitly create Docker images prior to deploying the service on Kubernetes. See [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

Since this guide requires `ActiveMQ` as a prerequisite, you need an additional step as follows to create a pod for `ActiveMQ` to use it with the sample.  

- Navigate to the `message_construction_patterns/resources` directory and run the following command:  

```bash
   $ kubectl create -f ./kubernetes/
```
This creates the ActiveMQ pod by creating a deployment and service for ActiveMQ. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` directory.

- Now let's see how to deploy the `phone_store_service` on Kubernetes. You need to import `` ballerinax/kubernetes `` and use ``@kubernetes``annotations as shown below to enable the kubernetes deployment.

> NOTE: Linux users can use Minikube to try this out locally.

#####  phone_store_service.bal

```ballerina
import ballerinax/kubernetes;

// Type definition for a phone order
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];
// 'jms:Connection' definition
// 'jms:Session' definition
// 'jms:QueueSender' endpoint definition

@kubernetes:Ingress {
hostname:"ballerina.guides.io",
name:"ballerina-guides-phone_store_service",
path:"/"
}

@kubernetes:Service {
serviceType:"NodePort",
name:"ballerina-guides-phone_store_service"
}

@kubernetes:Deployment {
image:"ballerina.guides.io/phone_store_service:v1.0",
name:"ballerina-guides-phone_store_service"
}

endpoint http:Listener listener {
port:9090
};

@http:ServiceConfig {basePath:"/phonestore"}
service<http:Service> phone_store_service bind listener {
``` 

- Here you use ``  @kubernetes:Deployment `` to specify the Docker image name that will be created as part of building the service. 
- You need to specify `` @kubernetes:Service `` so that it can create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- You need to use `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

If you are using Minikube, you need to set a couple of additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). The IP address of the cluster can be found by running the `minikube ip` command.

- Now you can use the following command to build a Ballerina executable archive (.balx) of the service that you developed: 
> NOTE: This also creates the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured.
  
```
   $ ballerina build 
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run the following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_store_service/kubernetes
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run the following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_order_delivery_service/kubernetes
    
```
- Use the docker images command to verify whether the Docker image that you specified in `@kubernetes:Deployment` is created.
- The Kubernetes artifacts related to the service should be generated in the`` ./target/phone_order_delivery_service/kubernetes`` directory.
- Now you can execute the following command to create the Kubernetes deployment:

```bash
   $ kubectl apply -f ./target/phone_store_service/kubernetes
   
   deployment.extensions "ballerina-guides-phone_store_service" created
   ingress.extensions "ballerina-guides-phone_store_service" created
   service "ballerina-guides-phone_store_service" created
   
   kubectl apply -f ./target/phone_order_delivery_service/kubernetes
   
   deployment.extensions "ballerina-guides-phone_order_delivery_service" created
   ingress.extensions "ballerina-guides-phone_order_delivery_service" created
   service "ballerina-guides-phone_order_delivery_service" created
```

- You can use the following commands to verify whether the Kubernetes deployment, service, and ingress are running properly:

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```
- "If all artifacts are successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"  
```
If you are using Minikube, you should use the IP address of the Minikube cluster that you can obtain by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.
```bash
    $ minikube ip
    192.168.99.100

    $ kubectl get services
    NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
    ballerina-guides-phone_store_service   NodePort    10.100.0.22   <none>        9090:30659/TCP   3h
```
The endpoint URL for the above case would be as follows: `http://192.168.99.100:30659/phonestore/placeOrder`

Ingress:

Add the `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
``` 
   127.0.0.1 ballerina.guides.io
```
Access the service 
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json" 
```
## Observability 
Ballerina is observable by default. This means that you can easily observe your services and resources using Ballerina.
However, observability is disabled by default via configuration. To enable observability, you should add the following configurations to the `ballerina.conf` file and start the Ballerina service. 
You can find a sample configuration file in `message_construction_patterns/guide/phone_store_service`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

To start the Ballerina service using the configuration file, execute the following command:
```
   $ ballerina run --config phone_store_service/ballerina.conf phone_store_service/
```
> NOTE: The above configuration is the minimum configuration required to enable tracing and metrics. With these configurations, the default values load as configuration parameters of metrics and tracing.

### Tracing 

You can monitor Ballerina services using the built-in tracing capabilities of Ballerina. You can use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the steps below to use tracing with Ballerina.

- You can add the following configurations for tracing. 
> NOTE: These configurations are optional if you already have the basic configuration in the `ballerina.conf` file as described in the [Observability](#observability) section.

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

- Run Jaeger Docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `message_construction_patterns/guide` and run the `phone_store_service` using the following command
```
   $ ballerina run --config phone_store_service/ballerina.conf phone_store_service/
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```
### Metrics
Metrics and alerts are built-in with Ballerina. You can use Prometheus as the monitoring tool.
Follow the steps below to set up Prometheus and view metrics for the phone_store_service.

- You can add the following configurations for metrics. 
> NOTE:  The following configurations are optional if you already have the basic configuration in `ballerina.conf` as described in the `Observability` section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
```

- Create a file named `prometheus.yml` inside the `/tmp/` directory and add the following configurations to the `prometheus.yml` file:
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

 > NOTE: Be sure to replace `172.17.0.1` if your local Docker IP is different from `172.17.0.1`
   
- Execute the following command to run the Prometheus Docker image:
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `message_construction_patterns/guide` and run the `phone_store_service` using the following command:
```
   $ ballerina run --config phone_store_service/ballerina.conf phone_store_service/
```

- You can access Prometheus via the following URL:
```
   http://localhost:19090/
```

> NOTE: Ballerina has the following metrics by default for the HTTP server connector. You can enter following expression in the Prometheus UI:
-  http_requests_total
-  http_response_time

### Logging
The Ballerina log package provides various functions that you can use to print log messages on the console depending on your requirement. You can import the ballerina/log package and start logging. The following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

- Navigate to `message_construction_patterns/guide` and start the Ballerina service using the following command:
```
   $ nohup ballerina run phone_store_service/ &>> ballerina.log&
```
 > NOTE: This writes console logs to the `ballerina.log` file in the `message_construction_patterns/guide` directory.

- Execute the following command to start Elasticsearch:
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

 > NOTE: Linux users may need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Execute the following command to start the Kibana plugin for data visualisation with Elasticsearch:
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```

- Follow the steps below to configure logstash to format Ballerina logs:

i) Create a file named `logstash.conf` with the following content:
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

ii) Save the `logstash.conf` file inside a directory named `{SAMPLE_ROOT}\pipeline`
     
iii) Execute the following command to start the logstash container.

> NOTE: Be sure to replace {SAMPLE_ROOT} with your directory name.
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
  
 - Follow the steps below to configure filebeat to ship Ballerina logs:
    
i) Create a file named `filebeat.yml` with the following content:
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
> NOTE: You can use the `$chmod go-w filebeat.yml` command to modify the ownership of the filebeat.yml file. 

ii) Save the `filebeat.yml` file inside a directory named `{SAMPLE_ROOT}\filebeat`.  
        
iii) Execute the following command to start the logstash container.

> NOTE: Be sure to replace {SAMPLE_ROOT} with your directory name.
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/phone_store_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Use the following URL to access Kibana and visualize logs:
```
   http://localhost:5601 
```
