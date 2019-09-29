# Ballerina as a JMS Producer and a Consumer

This guide walks you through the process of using Ballerina to handle files read using FTP protocol and how to scale the file processing with JMS queues using a message broker. 

#### What you'll build

In this example, we'll implement the following.
* ftp listener which will listen to a remote directory and periodically notify the file addition of the specified file pattern.

* Add the read files to a jms queue, "FileQueue".

* JMS message consumer polls the "FileQueue" and gets the file details whenever the queue becomes populated

* Process the files in the FileQueue based upon the processing logic.

In this example Apache ActiveMQ has been used as the JMS broker.<br/>
Ballerina JMS Connector is used to connect Ballerina and JMS Message Broker.<br/>
With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message Producer.

#### Prerequisites

* Ballerina Distribution
* A Text Editor or an IDE <br/>
    Tip: For a better development experience, install one of the following Ballerina IDE plugins: VSCode, IntelliJ IDEA
* Install ftp connectors by following the below steps.<br/>
1. Download correct distribution.zip from releases (we can get it from the link given below) that match with ballerina version. <br/>
https://github.com/wso2-ballerina/module-ftp<br/>
2. Unzip package distribution.<br/>
3. Run the install.<sh|bat> script to install the package. You can uninstall the package by running uninstall.<sh|bat>.  <br/>
4. FTP server and client
5. A JMS Broker (Example: Apache ActiveMQ)
6. After installing the JMS broker, copy its .jar files into the <BALLERINA_HOME>/bre/lib folder <br/>
For ActiveMQ 5.15.4: Copy activemq-client-5.15.4.jar, geronimo-j2ee-management_1.1_spec-1.0.1.jar and hawtbuf-1.11.jar 


### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Creating the Project Structure](#creating-the-project-structure)
  - [Implementing the FTP Listener and JMS Producer.](#Implementing-the-FTP-Listener-and-JMS-Producer)
     - [Implementing the FTP Listener](#Implementing-the-FTP-Listener)
     - [Implementing the JMS Producer](#Implementing-the-JMS-Producer)   
  - [Implement the FTP client and JMS message receiver](#Implement-the-FTP-client-and-JMS-message-receiver)
    - [Implementing the FTP Client](#Implementing-the-FTP-Client)
    - [Implementing the JMS Consumer](#Implementing-the-JMS-Consumer) 
  - [Scaling the message processing using multiple jms consumers](#Scaling-the-message-processing-using-multiple-jms-consumers)
- [Deployment](#deployment)
  - [Deploying Locally](#deploying-locally)
  - [Deploying on Docker](#deploying-on-docker)
- [Testing](#testing)
  - [Invoking the Database Service](#invoking-the-database-service)

### Implementation

#### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
    └── guide
        ├── ballerina.conf
        └── file-integration
            └── sacling-consumers
                ├── message_producer.bal 
                ├── message_receiver.bal
                └── queue_service.bal
                   
```
        
Create the above directories in your local machine and also create empty .bal files.

Then open the terminal and navigate to file-integration and run Ballerina project initializing toolkit.

```ballerina
   $ ballerina init
```

#### Implementing the FTP Listener and JMS Producer.

First we'll implement the FTP Listener and JMS  producer inside the message_producer.bal file. 

##### Implementing the FTP Listener

FTP Listener can be used to listen to a remote directory. It will keep listening to the specified directory and periodically notify the file addition and deletion.

For this we have to import the ballerina ftp_module.

   ```ballerina
   import wso2/ftp;
   ```

Define a record to define the following configurations for processing the file.

 ```ballerina
   type Config record {
        string fileNamePattern;
        string destFolder;
        string errFolder;
        Operation opr ;     
   };
   ```

The following table explains the configuration parameters defined in the record.

| Parameter Name                                            | Description                                                                                                                            |
|-----------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| fileNamePattern                                           | Can be used to process only the files with the given fileNamePattern available at the specified file URI location.<br/> fileNamePattern can be given using a regular expression." |                                                                                                                                        |
| destFolder                                                | Where to move the files after processing if Operation is MOVE.                                                                         |
| errFolder                                                 | Where to move the files if processing fails.                                                                                           |
| opr                                                       | Whether to Move or Delete the file after processing.                                                                                   |
  
Give the configurations as inputs. 

```ballerina
    Config conf = {
        fileNamePattern: ".*.json",
        destFolder: "/movedFolder",
        errFolder: "/errFoldr",
        opr: MOVE  
    };
 ```

5. Create a ftp listener instance by giving the following configurations.

```ballerina
    listener ftp:Listener remoteServer = new({
        protocol: ftp:FTP,
        host: config:getAsString("FTP_HOST"),
        port: config:getAsInt("FTP_LISTENER_PORT"),
        pollingInterval:config:getAsInt("FTP_POLLING_INTERVAL"),
        fileNamePattern:conf.fileNamePattern,
        secureSocket: {
            basicAuth: {
                username: config:getAsString("FTP_USERNAME"),
                password: config:getAsString("FTP_PASSWORD")
            }
        },
        path: config:getAsString("FTP_LISTEN_FOLDER")
});
```

The fileResource service will listen to the folder defined in "FTP_LISTEN_FOLDER" and and periodically notify the file addition.

##### Implementing the JMS Producer

In Ballerina, you can directly set the JMS configuration in the endpoint definition.

In the below code, fileResource is a JMS producer service that handles the JMS message producing logic.<br/>

jms:Connection is used to initialize a JMS connection with the provider details. initialContextFactory and providerUrl configuration change based on the JMS provider you use.

jms:Session is used to initialize a session with the required connection properties.

Here the files read by the FTP listener is added to the FileQueue and these will be consumed by fileConsumingSystem later.

Now let's implement the JMS consumer.

* Initialize a JMS connection with the provider.
Please note that 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use.<br/>
In this guide 'Apache ActiveMQ' has been used as the message broker in this example.

```ballerina
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });
```
* Initialize a JMS session on top of the created connection

```ballerina
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });
```

* Initialize a queue sender using the created session

```ballerina
jms:QueueSender queueSender = new(jmsSession, queueName = "FileQueue");
```
Skeleton of the message_producer.bal is given below. Inline comments added for better understanding.

```ballerina
import wso2/ftp;
import ballerina/log;
import ballerina/io;
import ballerina/internal;
import ballerina/config;
import ballerina/http;
import ballerina/jms;
import wso2ftputils;

type Config record {
    string fileNamePattern;
    string destFolder;
    string errFolder;
    Operation opr;
};

// Define a record to get the following configurations for processing the file.
Config conf = {
    fileNamePattern: ".*.json",
    destFolder: "/movedFolder",
    errFolder: "/errFoldr",
    opr: MOVE
};

// Creating a ftp listener instance by defining the configuration.
listener ftp:Listener remoteServer = new({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    pollingInterval:config:getAsInt("FTP_POLLING_INTERVAL"),
    fileNamePattern:conf.fileNamePattern,  
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: "/newFolder"
});

//Initialize a JMS connection with the provider.
jms:Connection jmsConnection = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session jmsSession = new(jmsConnection, {
    acknowledgementMode: "AUTO_ACKNOWLEDGE"
});

jms:QueueSender queueSender = new(jmsSession, queueName = "FileQueue");

service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("Added file path: " + v1.path);
            // Create a text message.
            var msg = jmsSession.createTextMessage(v1.path);
            if (msg is error) {
                log:printError("Error occurred while creating message", err = msg);
            } else {
                // Adding the read file names to the jms queue
                var result = queueSender->send(msg);
                if (result is error) {
                    log:printError("Error occurred while sending message", err = result);
                }
            }
        }
    }
}
```
#### Implement the FTP client and JMS message receiver
##### Implement FTP Client

The FTP Client can be used to connect to a FTP server and perform I/O operations.

* Define the union type of the actions that can be performed after processing the file.
Define ERROR type also as an error can also be returned if the file processing fails.

```ballerina
public const MOVE = "MOVE";
public const DELETE = "DELETE";
public const ERROR = "ERROR";

// Define the union type of the actions that can be performed after processing the file.
public type Operation MOVE|DELETE|ERROR;
```

* Define the configuration of the ftp client endpoint.
```ballerina
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};
```

* Create a ftpClient object.
ftp:Client ftpClient = new(ftpConfig);


##### Implement the JMS message Consumer

In the below code, fileConsumingSystem is a JMS consumer service that handles the JMS message consuming logic.<br/>
This service is attached to a jms:QueueReceiver endpoint that defines the jms:Session and the queue to which the messages are added.

* Initialize a JMS connection with the provider as we did in the JMS Producer.
```ballerina
jms:Connection conn = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
});
```

* Initialize a JMS session on top of the created connection.
```ballerina
jms:Session jmsSessionRe = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
});
```
* Initialize a queue receiver using the created session.
```ballerina
listener jms:QueueReceiver jmsConsumer = new(jmsSessionRe, queueName = "FileQueue");
```

* Resource onMessage will be triggered whenever the queue specified as the destination (FileQueue) gets populated.

Skeleton of the message_receiver.bal is attached below
```ballerina
service fileConsumingSystem on jmsConsumer {
    // Triggered whenever an order is added to the 'FileQueue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New File received from the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("File Details: " + stringPayload);

            //processing logic
            var proRes = processFile(stringPayload);

            if (proRes == MOVE) {
                // Moving the file to another location on the same ftp server after processing.
                string destFilePath = createFolderPath(stringPayload, conf.destFolder);
                error? renameErr = ftpClient->rename(stringPayload, destFilePath);
            } else if (proRes == DELETE) {
                // Delete the file after processing
                error? fileDelCreErr = ftpClient->delete(stringPayload);
                log:printInfo("Deleted File after processing");

            } else {
                // Move the file to another location on the same ftp server if an error occurred during processing
                string errFoldPath = createFolderPath(stringPayload, conf.errFolder);
                error? processErr = ftpClient->rename(stringPayload, errFoldPath);
            }
        } else {
            log:printInfo("Error occurred while retrieving the order details");
        }       
    }
}

// Processing logic that needs to be done on the file content based on the file type.
public function processFile(string sourcePath) returns Operation {

    var getResult = ftpClient->get(sourcePath);
    Operation res = MOVE;

    // implementation of the processing logic
}

```

#### Scaling the message processing using multiple jms consumers

When we want to scale the processing of the files added to the queue, we can add multiple jms consumers as per our requirement.

The skeleton code for adding a new JMS consumer is given below.
```ballerina
import ballerina/log;
import ballerina/io;
// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conne = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSessionRes = new(conne, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session
listener jms:QueueReceiver jmsConsumer1 = new(jmsSessionRes, queueName = "FileQueue");


service fileConsumingSystems on jmsConsumer1 {
    // Triggered whenever an order is added to the 'FileQueue'
    resource function onMessage(jms:QueueReceiverCaller consumers, jms:Message messages) {
        log:printInfo("New File received from the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = messages.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("File Details: " + stringPayload);

            // Implement the processing logic and action to be done after processing            
    }
}
```
### Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying Locally

To deploy locally, navigate to *guides/file-integration*, and execute the following command.

```
$ ballerina build
```

This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder.
You can run them with the command:

```
$ ballerina run <Executable_File_Name>
```

#### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container. Ballerina language includes a Ballerina_Docker_Extension, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

### Testing
#### Invoking the service

When we upload a file with the same file name pattern defined in the configs to the folder defined in the ftp listener instance the ftp listener will invoke, process the file and do the operation defined in the configs (i.e either Move to the defined folder or Delete the processed) if the processing is successful. <br/>
If the processing is unsuccessful the file is moved to the folder defined.

