[![Build Status](https://travis-ci.org/SavithriNandadasa/message_construction_patterns.svg?branch=master)](https://travis-ci.org/SavithriNandadasa/message_construction_patterns)

# Message Construction Patterns

Message construction patterns describe the creation of message content that travel across messaging systems.It involves the architectural patterns of various constructs, functions, and activities involved in creating and transforming a message between applications.

Java Message Service (JMS) is used to send messages between two or more clients. JMS supports two models: point-to-point model and 
publish/subscribe model. A JMS synchronous invocation takes place when a JMS producer receives a response to a JMS request produced by it when invoked.

This is a simple example of how to use messaging, implemented in JMS. It shows how to implement Request-Reply, where a requestor application sends a request, a replier application receives the request and returns a reply, and the requestor receives the reply. 

> This guide walks you through the process of using Ballerina to message construction with JMS queues using a message broker.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understand how you can use JMS queues for messaging, let's consider a real-world use case of a phone store service using which a user can order phones for home delivery. This scenario contains two services.
- `phone_store_service` : A Message Endpoint that sends a request message and waits to receive a reply message as a response.
- `phone_order_delivery_service` : A Message Endpoint that waits to receive the request message; when it does, it responds by sending the reply message.

Once an order is placed, the `phone_store_service` will add it to a JMS queue named `OrderQueue` if the order is valid. Hence, this `phone_store_service` acts as the message requestor. And `phone_order_delivery_service`, which acts as the message replier and gets the order details whenever the queue becomes populated and forward them to `DeliveryQueue` using `phone_order_delivery_service`.

As this use case is based on message construction patterns, the scenario uses Request-Reply with a pair of Point-to-Point Channels. The request is a Command Message whereas the reply is a Document Message that contains the function's return value or exception.The below diagram illustrates this use case.

![alt text](/images/message_construction_patterns.png)


In this example `Apache ActiveMQ` has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message  
Producer.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A JMS Broker (e.g.: [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After installing the JMS broker, copy its .jar files into the `<BALLERINA_HOME>/bre/lib` folder
    * For ActiveMQ 5.15.4: Copy `activemq-client-5.15.4.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar` and `hawtbuf-1.11.jar`
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the source from the Git repo and directly move to the "Testing" section by skipping the "Implementation" section.    

### Create the project structure

Ballerina is an integration language that supports custom project structures. Use the following package structure for this guide.
```
message_construction_patterns
 └── guide
      ├── phone_store_service
      │    ├── phone_store_service.bal
      │    └── tests
      │         └── phone_store_service.bal
      └── phone_order_delivery_service
           ├──order_delivery_service.bal
           └── tests
                └── phone_order_delivery_service_test.bal

```

- Create the above directories in your local machine and initialize a Ballerina project.

- Then open the terminal and navigate to `message_construction_patterns/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```
### Developing the service

Let's get started with the implementation of the `phone_store_service`, which acts as the message Requestor. 
Refer to the code attached below. Inline comments added for better understanding.

##### phone_store_service.bal

```ballerina
import ballerina/http;
import ballerina/jms;
import ballerina/log;

// Type definition for a phone order
type PhoneOrder record {
    string customerName;
    string address;
    string contactNumber;
    string orderedPhoneName;
};

// Global variable containing all the available phones
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection orderQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a JMS session on top of the created connection
jms:Session orderQueueJmsSessionSend = new(orderQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducerOrderQueue {
    session: orderQueueJmsSessionSend,
    queueName: "OrderQueue"
};
// Service endpoint
endpoint http:Listener listener {
    port: 9090
};

//backendreq used to obtain details of order queue
public http:Request backendreq;

// phone store service, which allows users to order phones online for delivery
@http:ServiceConfig { basePath: "/phonestore" }
service<http:Service> phoneStoreService bind listener {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    placeOrder(endpoint caller, http:Request request) {

        backendreq = untaint request;
        http:Response response;
        PhoneOrder newOrder;
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
        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = caller->respond(response);
            done;
        }
        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newOrder.orderedPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneOrderDetails = check <json>newOrder;
            // Create a JMS message
            jms:Message queueMessage = check orderQueueJmsSessionSend.createTextMessage(phoneOrderDetails.toString());

            log:printInfo("order will be added to the order  Queue; CustomerName: '" + newOrder.customerName +
                    "', OrderedPhone: '" + newOrder.orderedPhoneName + "';");

            // Send the message to the JMS queue
            _ = jmsProducerOrderQueue->send(queueMessage);

            // Construct a success message for the response
            responseMessage = { "Message": "Your order was successfully placed. Ordered phone will be delivered soon" };
        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = { "Message": "Requested phone not available" };
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller->respond(response);
    }
    // Resource that allows users to get a list of all the available phones
    @http:ResourceConfig { methods: ["GET"], produces: ["application/json"] }
    getPhoneList(endpoint client, http:Request request) {
        http:Response response;
        // Send json array 'phoneInventory' as the response, which contains all the available phones
        response.setJsonPayload(phoneInventory);
        _ = client->respond(response);
    }
}
jms:Connection orderQueueJmsConnectionRecieve = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session orderQueueJmsSessionRecieve = new(orderQueueJmsConnectionRecieve, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumerOrderQueue {
    session: orderQueueJmsSessionRecieve,
    queueName: "OrderQueue"
};
// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDeliverySystem bind jmsConsumerOrderQueue {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message) {
        log:printInfo("New order successfilly received from the Order Queue");
        // Retrieve the string payload using native function
        string stringPayload = check message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);

        //send order queue details to delivery queue
        http:Request enrichedreq = backendreq;
        var clientResponse = phone_order_delivery_serviceEP->forward("/", enrichedreq);
        match clientResponse {
            http:Response res => {
                log:printInfo("Order details were sent to phone_order_delivery_service.");
            }
            error err => {
                log:printError("Order details were not sent to phone_order_delivery_service.");
            }
        }
    }
}
endpoint http:Client phone_order_delivery_serviceEP {
    url: "http://localhost:9091/deliveryDetails/sendDelivery"
};


```
Now let's consider the implementation of `order_delivery_service.bal` which acts as the message Replier.

#### order_delivery_service.bal

```ballerina
import ballerina/http;
import ballerina/jms;
import ballerina/log;

type PhoneDeliver record {
    string customerName;
    string address;
    string contactNumber;
    string deliveryPhoneName;
};
json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

jms:Connection DeliveryQueueJmsConnectionSend = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducerDeliveryQueue {
    session: DeliveryQueueJmsSessionSend,
    queueName: "DeliveryQueue"
};
// Initialize a JMS session on top of the created connection
jms:Session DeliveryQueueJmsSessionSend = new(DeliveryQueueJmsConnectionSend, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Service endpoint
endpoint http:Listener deliveryEP {
    port: 9091
};

@http:ServiceConfig { basePath: "/deliveryDetails" }
// phone store service, which allows users to order phones online for delivery
service<http:Service> phoneOrderDeliveryService bind deliveryEP {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    sendDelivery(endpoint caller, http:Request enrichedreq) {
        http:Response response;
        PhoneDeliver newDeliver;
        json reqPayload;

        log:printInfo(" Received order details from the phone store service");

        // Try parsing the JSON payload from the request
        match enrichedreq.getJsonPayload() {
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
        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = caller->respond(response);
            done;
        }
        // Order details
        newDeliver.customerName = name.toString();
        newDeliver.address = address.toString();
        newDeliver.contactNumber = contact.toString();
        newDeliver.deliveryPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newDeliver.deliveryPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }
        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneDeliverDetails = check <json>newDeliver;
            // Create a JMS message

            jms:Message queueMessage2 = check DeliveryQueueJmsSessionSend.createTextMessage(phoneDeliverDetails.toString
                ());

            log:printInfo("Order delivery details added to the delivery queue'; CustomerName: '" + newDeliver.
                    customerName +
                    "', OrderedPhone: '" + newDeliver.deliveryPhoneName + "';");
            // Send the message to the JMS queue
            _ = jmsProducerDeliveryQueue->send(queueMessage2);
            // Construct a success message for the response
            responseMessage = { "Message": "Your order was successfully placed. Ordered phone will be delivered soon" };
        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = { "Message": "Requested phone not available" };
        }
        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller->respond(response);
    }
}
jms:Connection DeliveryQueueJmsConnectionReceive = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
// Initialize a JMS session on top of the created connection
jms:Session DeliveryQueueJmsSessionReceive = new(DeliveryQueueJmsConnectionReceive, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumerDeliveryQueue {
    session: DeliveryQueueJmsSessionReceive,
    queueName: "DeliveryQueue"
};
service<jms:Consumer> deliverySystem bind jmsConsumerDeliveryQueue {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message2) {
        log:printInfo("New order successfilly received from the Delivery Queue");
        // Retrieve the string payload using native function
        string stringPayload2 = check message2.getTextMessageContent();
        log:printInfo("Delivery details: " + stringPayload2);
        log:printInfo(" Delivery details sent to the customer successfully");
    }
}

```


## Testing 

### Invoking the service

- First, start the `Apache ActiveMQ` server by entering the following command in a terminal from `<ActiveMQ_BIN_DIRECTORY>`.

```bash
   $ ./activemq start
```

- Navigate to `message_construction_patterns/guide` and run the following commands in separate terminals to start both `phone_store_service` and `order_delivery_service`.
```bash
   $ ballerina run phone_store_service.bal
```

```bash
   $ ballerina run order_delivery_system
```
   
- Invoke the `phone_store_service` by sending a GET request to check the available phones.

```bash
   curl -v -X GET localhost:9090/phonestore/getPhoneList
```

  The `phone_store_service` sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   ["Apple:190000","Samsung:150000","Nokia:80000","HTC:40000","Huawei:100000"]
```
   
- Place an order using the following command.

```bash
   curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
   
```

  The `phone_store_service`e sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   {"Message":"Your order was successfully placed. Ordered phone will be delivered soon"} 
```

  Sample Log Messages:
```bash

  INFO  [phone_store_service] - order will be added to the order  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_store_service] - New order successfilly received from the Order Queue 
  INFO  [phone_store_service] - Order Details: {"customerName":"John","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94718930874","orderedPhoneName":"Apple:190000"} 
  
  Order details were sent to phone_order_delivery_service

  Received order details from phone_store_service.
  
  INFO  [phone_order_delivery_service] - Order delivery details  added to the delivery  Queue; CustomerName: 'Bob', OrderedPhone: 'Apple:190000'; 
  INFO  [phone_order_delivery_service] - New order successfilly received from the Delivery Queue 
  INFO  [phone_order_delivery_service] - Order details: {"customerName":"Bob","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94777123456","orderedPhoneName":"Apple:190000"} 
  
 Delivery details sent to the customer successfully
 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.

```ballerina
   @test:Config
   function testResourcePlaceOrder() {
```
  
This guide contains unit test cases for each resource available in the `phone_store_service` implemented above. 

To run the unit tests, navigate to `message_construction_patterns/guide` and run the following command. 
```bash
   $ ballerina test
```

When running these unit tests, make sure that the JMS Broker is up and running.

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `message_construction_patterns/guide` and run the following command.

```bash
   $ ballerina build
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output.
```
   ballerina: initiating service(s) in 'phone_store.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
   
   ballerina: initiating service(s) in 'phone_order_delivery_service.balx' 
   ballerina: started HTTP/WS endpoint 0.0.0.0:9091
```
### Deploying on Docker

You can run the service that we developed above as a Docker container.
As ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers,
you just need to add the corresponding Docker annotations to your service code.
Since this guide requires `ActiveMQ` as a prerequisite, you need a couple of more steps to configure it in a Docker container.   

First let's see how to configure `ActiveMQ` in a Docker container.

- Initially, you need to pull the `ActiveMQ` Docker image using the following command.
```bash
   $ docker pull webcenter/activemq
```

- Then launch the pulled image using the following command. This will start the `ActiveMQ` server in Docker with default configurations.
```bash
   $ docker run -d --name='activemq' -it --rm -P webcenter/activemq:latest
```

- Check whether the `ActiveMQ` container is up and running using the following command.
```bash
   $ docker ps
```

Now let's see how we can deploy the `phone_store_service` and `phone_order_delivery_service` on Docker. We need to import `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation at build time. 

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
Similar to the `phone_store_service.bal`, We define the `@docker:Config` and `@docker:Expose {}` in  `phone_order_delivery_service` for Docker deployment.

- `@docker:Config` annotation is used to provide the basic Docker image configurations for the sample.`@docker:Expose {}` is used to expose the port. 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `message_construction_patterns/guide` and run the following command.  
  
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

- Once you successfully build the Docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```bash
  docker run -d -p 9090:9090 ballerina.guides.io/phone_store_service:v1.0
  docker run -d -p 9091:9091 ballerina.guides.io/phone_order_delivery_service:v1.0  
```

   Here we run the Docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify Docker container is running with the use of `` $ docker ps``. The status of the Docker container should be shown as 'Up'. 

- You can access the service using the same curl commands that we've used above.
```bash
    curl -v -X POST -d \
   '{"Name":"John", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94718930874", "PhoneName":"Apple:190000"}' \
   "http://localhost:9090/phonestore/placeOrder" -H "Content-Type:application/json"
```
### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support to run a Ballerina program on Kubernetes, with the use of Kubernetes annotations that you can include as part of your 
service code. Also, it will take care of the creation of the Docker images. So you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Since this guide requires `ActiveMQ` as a prerequisite, you need an additional step to create a pod for `ActiveMQ` and use it with our sample.  

- Navigate to `message_construction_patterns/resources` directory and run the below command to create the ActiveMQ pod by creating a deployment and service for ActiveMQ. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` folder.

```bash
   $ kubectl create -f ./kubernetes/
```

- Now let's see how we can deploy the `phone_store_service` on Kubernetes. We need to import `` ballerinax/kubernetes `` and use ``@kubernetes``annotations as shown below to enable kubernetes deployment.

> NOTE: Linux users can use Minikube to try this out locally

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

- Here we have used ``  @kubernetes:Deployment `` to specify the Docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

If you are using Minikube, you need to set a couple of additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). The IP address of the cluster can be found by running the `minikube ip` command.

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build 
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_store_service/kubernetes
   
   @kubernetes:Service                      - complete 1/1
   @kubernetes:Ingress                      - complete 1/1
   @kubernetes:Docker                       - complete 3/3 
   @kubernetes:Deployment                   - complete 1/1
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/phone_order_delivery_service/kubernetes
    
```
- Use the docker images command to verify whether the Docker image that you specified in `@kubernetes:Deployment` was created 
- Shall we rephrase this to "The Kubernetes artifacts related to the service are generated in `` ./target/phone_order_delivery_service/kubernetes`` directories."
- Now you can create the Kubernetes deployment using:

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

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

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
If you are using Minikube, you should use the IP address of the Minikube cluster obtained by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.
```bash
    $ minikube ip
    192.168.99.100

    $ kubectl get services
    NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
    ballerina-guides-phone_store_service   NodePort    10.100.0.22   <none>        9090:30659/TCP   3h
```
The endpoint URL for the above case would be as follows: `http://192.168.99.100:30659/phonestore/placeOrder`

Ingress:

Add `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
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
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file and starting the ballerina service using it. A sample configuration file can be found in `message_construction_patterns/guide/phone_store_service`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

To start the ballerina service using the configuration file, run the following command
```
   $ ballerina run --config phone_store_service/ballerina.conf phone_store_service/
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
Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for phone_store_service service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
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

   NOTE : Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`
   
- Run the Prometheus Docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `message_construction_patterns/guide` and run the `phone_store_service` using the following command
```
   $ ballerina run --config phone_store_service/ballerina.conf phone_store_service/
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

- Start the Ballerina Service with the following command from `message_construction_patterns/guide`
```
   $ nohup ballerina run phone_store_service/ &>> ballerina.log&
```
   NOTE: This will write the console log to the `ballerina.log` file in the `message_construction_patterns/guide` directory

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
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/phone_store_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```

