# IBM WebSphere MQ with Ballerina JMS connector

This guide is about connecting using ballerina/jms module with IBM WebSphere MQ. IBM MQ allows application programs to use a message-queuing technique to participate in message-driven processing.The ballerina/jms module provides an API to connect to an external JMS provider like Ballerina Message Broker,ActiveMQ or IBM WebSphere MQ. The ballerina/jms module provides consumer and producer endpoint types for queues and topics.

The high level sections of this guide are as follows:

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Deployment](#deployment)

## What you'll build

In this example, we have implemented a JMS Queue Message Producer which sends user input to the queue and JMS Queue Message Receiver implemented for the retrieves inserted messages from the queue. The Message Receiver can be done by the synchronous and asynchronous manner.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [IBM WebSphere MQ](https://www.ibm.com/developerworks/downloads/ws/wmq/)
  * After you [install IBM WebSphere MQ](https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_9.0.0/com.ibm.mq.ins.doc/q115250_.htm), copy the .jar files from the `<IBM_MQ_HOME>/java/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
   * If you use IBM WebSphere MQ version 9.0.0, you only have to copy `com.ibm.mq.allclient.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar`,`jms.jar`,`providerutil.jar` and `fscontext.jar`, from the `<IBM_MQ_HOME>/java/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.

## Implementation

Configurations related to a JMS connection
```
jms:Connection conn = new({
        initialContextFactory: "com.sun.jndi.fscontext.RefFSContextFactory",
        providerUrl: "file:/jndidirectory/",
        connectionFactoryName: "QueueConnectionFactory",
        username: "",
        password: ""        
    });
```
| Field Name| Data Type| Default Value| Description|
| ----------| --------| ----------| ------|
| initialContextFactory |[string](https://ballerina.io/learn/api-docs/ballerina/primitive-types.html#string)| wso2mbInitialContextFactory| JMS provider specific inital context factory|
| providerUrl |[string](https://ballerina.io/learn/api-docs/ballerina/primitive-types.html#string)| JMS provider specific provider URL used to configure a connection. (.Bindings File : If you have this bindings file, you can access MQ queues from any machine in the network.)|JMS provider specific provider URL used to configure a connection|
| connectionFactoryName |[string](https://ballerina.io/learn/api-docs/ballerina/primitive-types.html#string)| ConnectionFactory | JMS provider specific provider URL used to configure a connection. (.Bindings File : If you have this bindings file, you can access MQ queues from any machine in the network.)|
| username |[string?](https://ballerina.io/learn/api-docs/ballerina/primitive-types.html#string)| () | JUsername for the JMS connection.)|
| password |[string?](https://ballerina.io/learn/api-docs/ballerina/primitive-types.html#string)| () | Password for the JMS connection.)|
| properties |[map](https://ballerina.io/learn/api-docs/ballerina/builtin.html#map)| () | Additional properties use in initializing the initial context.)|

### Creating the project structure
Ballerina is a complete programming language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:

```
ibmmq-jms-connector
    ├── guide
        ├── jms_queue_message_producer.bal
        ├── jms_asynchronus_queue_message_receiver.bal
        └── jms_synchronus_queue_message_receiver.bal
```
     
- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to , and run the Ballerina project initializing toolkit.

```ballerina
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Developing the samples

1. Implement `jms_queue_message_producer.bal` which will send to Queue of IBM WebSphere MQ broker. 
2. Implement `jms_asynchronus_queue_message_receiver.bal` which will listen for Queue of IBM WebSphere MQ broker (Asynchronous manner). 
3. Implement `jms_synchronus_queue_message_receiver.bal` which will listen for Queue of IBM WebSphere MQ broker (Synchronous manner).

Take a look at the code below to understand how to implement each ballerina sample. 

**jms_queue_message_producer.bal**

JMS Queue Message Producer : Following is a queue sender program that explicitly initializes a JMS session to be used by the producer.

```
import ballerina/jms;
import ballerina/log;

// Initialize a JMS connection with the provider.
jms:Connection jmsConnection = new({
    initialContextFactory: "com.sun.jndi.fscontext.RefFSContextFactory",
    providerUrl: "file:/jndidirectory/",
    connectionFactoryName: "QueueConnectionFactory",
    username: "",
    password:""
});

// Initialize a JMS session on top of the created connection.
jms:Session jmsSession = new(jmsConnection, {
    acknowledgementMode: "AUTO_ACKNOWLEDGE"
});

jms:QueueSender queueSender = new(jmsSession, queueName = "Queue");

public function main(string... args) {
    // Create a text message.
    var msg = jmsSession.createTextMessage("Hello from Ballerina");
    if (msg is error) {
        log:printError("Error occurred while creating message", err = msg);
    } else {
        var result = queueSender->send(msg);
        if (result is error) {
            log:printError("Error occurred while sending message", err = result);
        }
    }
}
```
**jms_asynchronus_queue_message_receiver.bal**

JMS Queue Message Receiver : Following is a listener program that explicitly initializes a JMS session to be used in the consumer (Asynchronous Queue Receiver). 

```
    import ballerina/jms;
    import ballerina/log;
    import ballerina/io;

    // Initialize a JMS connection with the provider.
    jms:Connection conn = new({
        initialContextFactory: "com.sun.jndi.fscontext.RefFSContextFactory",
        providerUrl: "file:/jndidirectory/",
        connectionFactoryName: "QueueConnectionFactory",
        username: "",
        password:""        
    });

    // Initialize a JMS session on top of the created connection.
    jms:Session jmsSession = new(conn, {
        // An optional property that defaults to `AUTO_ACKNOWLEDGE`.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

    // Initialize a queue receiver using the created session.
    listener jms:QueueReceiver consumerEP = new(jmsSession, queueName = "Queue");

    // Bind the created consumer to the listener service.
    service jmsListener on consumerEP {
        // The `OnMessage` resource gets invoked when a message is received.
        resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
            // Retrieve the text message.
            var msg = message.getTextMessageContent();
            if (msg is string) {
                log:printInfo("Message : " + msg);
            } else {
                log:printError("Error occurred while reading message", err = msg);
            }
        }
    }
```
**jms_synchronus_queue_message_receiver.bal**

 Following is a listener program that explicitly initializes a JMS session to be used in the consumer in a blocking manner (Synchronous Queue Receiver). 

 ```
import ballerina/jms;
import ballerina/log;

    // Initialize a JMS connection with the provider.
    jms:Connection conn = new({
        initialContextFactory: "com.sun.jndi.fscontext.RefFSContextFactory",
        providerUrl: "file:/jndidirectory/",
        connectionFactoryName: "QueueConnectionFactory",
        username: "",
        password:""        
    });
    
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

listener jms:QueueReceiver queueReceiver = new(jmsSession, queueName = "Queue");

public function main() {
    jms:QueueReceiverCaller caller = queueReceiver.getCallerActions();
    var result = caller->receive(timeoutInMilliSeconds = 5000);

    if (result is jms:Message) {
        var messageText = result.getTextMessageContent();
        if (messageText is string) {
            log:printInfo("Message : " + messageText);
        } else {
            log:printError("Error occurred while reading message.",
                err = messageText);
        }
    } else if (result is ()) {

        log:printInfo("Message not received");

    } else {
        log:printInfo("Error receiving message : " +
                <string>result.detail().message);
    }
}

 ```
## Deployment

Once you are done with the development, you can deploy the samples using any of the methods listed below. 

### Deploying locally

To deploy locally, navigate to .bal file, and execute the following command.

```
$ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder. 
You can run them by 

```
$ ballerina run <Exec_Archive_File_Name>
