# Messaging with ActiveMQ

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on how to use ActiveMQ as the message broker for messaging in Ballerina. You can find other integration modules from the wso2-ballerina GitHub repository.

> Let’s take a look at a sample scenario to understand how to do the following using ActiveMQ as the message broker in Ballerina:
> - Create a one-way JMS producer (i.e., one way messaging, also known as fire and forget mode).
> - Create a JMS consumer.

## What you'll build
As the sample scenario let’s consider a real-world use case of an online order management system where the general message flow is as follows:
1. Users place their orders through the system.
2. A Ballerina service accepts the order requests that are placed, and sends the requests to a message broker queue. 
3. An order dispatcher Ballerina service routes the order requests to appropriate queues depending on the message content (i.e., the dispatcher validates the order type using message content and routes the message)
4. The respective Ballerina service consumes messages from each queue.

The following diagram illustrates the scenario:

![alt text](resources/messaging-with-activemq.svg)

<!-- INCLUDE_MD: ../../../../tutorial-prerequisites.md -->
* [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After you install ActiveMQ, copy the .jar files from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
   * If you use ActiveMQ version 5.12.0, you only have to copy `activemq-client-5.12.0.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar`, and `hawtbuf-1.11.jar` from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.

### Optional Requirements
- [Docker](https://docs.docker.com/engine/installation/)

<!-- INCLUDE_MD: ../../../../tutorial-get-the-code.md -->

## Implementation
> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from git and skip the [Implementation](#implementation) instructions.

### Creating the project structure
Ballerina is a complete programming language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:

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
      └── wholesale_order_process_service
	       └── wholesale_order_process_service.bal	
```
     
- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to messaging-with-activemq/guide, and run the Ballerina project initializing toolkit.

```ballerina
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Developing the service
First you need to implement `order_accepting_service.bal` to act as an HTTP endpoint that accepts requests from clients, and then publishes the request messages to a JMS destination. 
Then implement `order_dispatcher_service.bal` to process each message that the `Order_Queue` receives, and route orders to the appropriate destination queues depending on the message content. 
Next, implement `retail_order_process_service.bal` and `wholesale_order_process_service.bal` as listener services for the `retail_Queue` and `Wholesale_Queue` respectively.

Take a look at the code samples below to understand how to implement each service. 

**order_accepting_service.bal**
```ballerina
import ballerina/log;
import ballerina/http;
import ballerina/jms;

// Type definition for an order
type Order record {
    string customerID?;
    string productID?;
    string quantity?;
    string orderType?;
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
jms:QueueSender jmsProducer = new(jmsSession, queueName = "Order_Queue");

//export http listner port on 9090
listener http:Listener httpListener = new(9090);

// Order Accepting Service, which allows users to place order online
@http:ServiceConfig { basePath: "/placeOrder" }
service orderAcceptingService on httpListener {
    // Resource that allows users to place an order 
    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"],
        produces: ["application/json"] }
    resource function place(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        Order newOrder = {};
        json reqPayload = {};

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            reqPayload = payload;
        } else {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            _ = check caller->respond(response);
            return;
        }

        json customerID = reqPayload.customerID;
        json productID = reqPayload.productID;
        json quantity = reqPayload.quantity;
        json orderType = reqPayload.orderType;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (customerID == null || productID == null || quantity == null || orderType == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            _ = check caller->respond(response);
            return;
        }

        // Order details
        newOrder.customerID = customerID.toString();
        newOrder.productID = productID.toString();
        newOrder.quantity = quantity.toString();
        newOrder.orderType = orderType.toString();

        json responseMessage;
        var orderDetails = json.convert(newOrder);
        // Create a JMS message
        if (orderDetails is json) {
            var queueMessage = jmsSession.createTextMessage(orderDetails.toString());
            // Send the message to the JMS queue
            if (queueMessage is jms:Message) {
                _ = check jmsProducer->send(queueMessage);
                // Construct a success message for the response
                responseMessage = { "Message": "Your order is successfully placed" };
                log:printInfo("New order added to the JMS queue; customerID: '" + newOrder.customerID +
                        "', productID: '" + newOrder.productID + "';");
            } else {
                responseMessage = { "Message": "Error occured while placing the order" };
                log:printError("Error occured while adding the order to the JMS queue");
            }
        } else {
            responseMessage = { "Message": "Error occured while placing the order" };
            log:printError("Error occured while placing the order");
        }
        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = check caller->respond(response);
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
listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "Order_Queue");

// Initialize a retail queue sender using the created session
jms:QueueSender jmsProducerRetail = new(jmsSession, queueName = "Retail_Queue");

// Initialize a wholesale queue sender using the created session
jms:QueueSender jmsProducerWholesale = new(jmsSession, queueName = "Wholesale_Queue");

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service orderDispatcherService on jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) returns error? {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = message.getTextMessageContent();
        if (orderDetails is string) {
            log:printInfo("validating  Details: " + orderDetails);
            //Converting String content to JSON
            io:StringReader reader = new io:StringReader(orderDetails);
            var result = reader.readJson();
            var closeResult = reader.close();

            if (result is json) {
                //Retrieving JSON attribute "OrderType" value
                json orderType = result.orderType;
                //filtering and routing messages using message orderType
                if (orderType.toString() == "retail") {
                    // Create a JMS message
                    var queueMessage = jmsSession.createTextMessage(orderDetails);
                    if (queueMessage is jms:Message) {
                        // Send the message to the Retail JMS queue
                        _ = check jmsProducerRetail->send(queueMessage);
                        log:printInfo("New Retail order added to the Retail JMS Queue");
                    } else {
                        log:printError("Error while adding the retail order to the JMS queue");
                    }
                } else if (orderType.toString() == "wholesale"){
                    // Create a JMS message
                    var queueMessage = jmsSession.createTextMessage(orderDetails);
                    if (queueMessage is jms:Message) {
                        // Send the message to the Wolesale JMS queue
                        _ = check jmsProducerWholesale->send(queueMessage);
                        log:printInfo("New Wholesale order added to the Wholesale JMS Queue");
                    } else {
                        log:printError("Error while adding the wholesale order to the JMS queue");
                    }
                } else {
                    //ignoring invalid orderTypes
                    log:printInfo("No any valid order type recieved, ignoring the message, order type recieved - " +
                            orderType.toString());
                }
            } else {
                log:printError("Error occured while processing the order");
            }
        } else {
            log:printError("Invalid order details, error occured while processing the order");
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
listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "Retail_Queue");

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service orderDispatcherService on jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = message.getTextMessageContent();
        //Convert String Payload to the JSON
        if (orderDetails is string) {
            io:StringReader reader = new io:StringReader(orderDetails);
            var result = reader.readJson();
            var closeResult = reader.close();
            if (result is json) {
                log:printInfo("New retail order has been processed successfully; Order ID: '"
                        + result.customerID.toString() + "', Product ID: '"
                        + result.productID.toString() + "', Quantity: '"
                        + result.quantity.toString() + "';");
            } else {
                log:printError("Error occured while processing the order");
            }
        } else {
            log:printError("Invalid order details, error occured while processing the oder");
        }
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
listener jms:QueueReceiver jmsConsumer = new(jmsSession, queueName = "Wholesale_Queue");

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service orderDispatcherService on jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = message.getTextMessageContent();
        if (orderDetails is string) {
            //Convert String Payload to the JSON
            io:StringReader reader = new io:StringReader(orderDetails);
            var result = reader.readJson();
            var closeResult = reader.close();
            if (result is json) {
                log:printInfo("New wholesale order has been processed successfully; Order ID: '"
                        + result.customerID.toString() + "', Product ID: '"
                        + result.productID.toString() + "', Quantity: '"
                        + result.quantity.toString() + "';");
            } else {
                log:printError("Error occured while processing the order");
            }
        } else {
            log:printError("Invalid order details, error occured while processing the order");
        }
    }
}

```

## Testing

### Invoking the service
Follow the steps below to invoke the service.

- On a new terminal, navigate to `<AMQ_HOME>/bin`, and execute the following command to start the ActiveMQ server.

```
   $ ./activemq start
```
- Navigate to messaging-with-activemq/guide, and execute the following commands via separate terminals to start each service:
 
```ballerina
   $ ballerina run order_accepting_service
   $ ballerina run order_dispatcher_service
   $ ballerina run retail_order_process_service
   $ ballerina run wholesale_order_process_service
```
- You can use the following requests to simulate placing retail and wholesale orders:

```
curl -d '{"customerID":"C001","productID":"P001","quantity":"4","orderType":"retail"}' -H "Content-Type: application/json" -X POST http://localhost:9090/placeOrder/place
 
curl -d '{"customerID":"C002","productID":"P002","quantity":"40000","orderType":"wholesale"}' -H "Content-Type: application/json" -X POST http://localhost:9090/placeOrder/place
 
```
#### Output
You will see the following log, which confirms that the `order_accepting_service` has received the request.

```
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
2018-08-21 08:17:17,701 INFO  [] - New order added to the JMS Queue; customerID: 'C001', productID: 'P001';
```
Order dispatcher service routes the messages.
```
2018-08-21 08:16:17,704 INFO  [ballerina/jms] - Message receiver created for queue Order_Queue 
2018-08-21 08:17:17,703 INFO  [] - New order received from the JMS Queue 
2018-08-21 08:17:17,704 INFO  [] - validating  Details: {"customerID":"C001","productID":"P001","quantity":"4","orderType":"retail"} 
2018-08-21 08:17:17,959 INFO  [] - New Retail order added to the Retail JMS Queue 
```
Retail order service consumes the message
```
ballerina: initiating service(s) in 'retail_order_process_service.bal'
2018-08-21 08:16:28,586 INFO  [ballerina/jms] - Message receiver created for queue Retail_Queue 
2018-08-21 08:17:17,956 INFO  [] - New order received from the JMS Queue 
2018-08-21 08:17:18,173 INFO  [] - New retail order has been processed successfully; Order ID: 'C001', Product ID: 'P001', Quantity: '4'; 
```

## Deployment
Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally
To deploy locally, navigate to messaging-with-activemq/guide, and execute the following command.

```ballerina
   $ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed. 

Once the .balx files are created inside the target folder, you can use the following command to run the .balx files:

```ballerina
   $ ballerina run <Exec_Archive_File_Name>
```
Successful execution of a service displays an output similar to the following:

```
ballerina: initiating service(s) in 'order_accepting_service.balx'
ballerina: initiating service(s) in 'order_dispatcher_service.balx'
ballerina: initiating service(s) in 'retail_order_process_service.balx'
ballerina: initiating service(s) in 'wholesale_order_process_service.balx'
```
