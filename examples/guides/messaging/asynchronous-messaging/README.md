# Asynchronous Messaging

This guide demonstrates how to send a message asynchronously to an HTTP service. It uses ActiveMQ as the message broker to make the invocation asynchronous. 

The high level sections of this guide are as follows:

- [What you'll build](#What-youll-build)
- [Prerequisites](#Prerequisites)
- [Implementation](#Implementation)
  - [Creating the project structure](#Creating-the-project-structure)
  - [Developing the service](#Developing-the-service)
- [Deployment](#Deployment)
  - [Deploying locally](#Deploying-locally)
  - [Deploying on Docker](#Deploying-on-Docker)
- [Testing](#Testing)
  - [Output](#Output)

## What you'll build
Let's consider a real world scenario where customers use a doctor channeling service. It facilitates channeling doctors at different hospitals registered in the system. The system will process appointment request at it's own pace rather than in real time. Users are only notified as requests are accepted. 

Here, the message is forwarded to ActiveMQ broker. If the message is sent without an issue, the user receives a successful message acceptance response. A separate service that listens to the queue picks up the message and invokes the intended backend service. For simplicity, we will omit the requirement of retrying delivery on a failure to deliver message to the HTTP endpoint.

The following diagram illustrates the scenario:

![alt text](https://raw.githubusercontent.com/pramodya1994/ballerina-integrator/hugo-site/examples/guides/messaging/asynchronous-messaging/resources/Asynchronous_service_invocation.png)



## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
 * After you install ActiveMQ, copy the .jar files from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
 * If you use ActiveMQ version 5.12.0, you only have to copy `activemq-client-5.12.0.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar`, and `hawtbuf-1.11.jar` from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.

## Implementation
> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from GitHub and skip the [Implementation](#implementation) instructions.

Take a look at the code samples below to understand how to implement each service. 

**http_message_receiver.bal**
<!-- INCLUDE_CODE: guide/http_message_receiver.bal -->

**message_forwarder.bal**
<!-- INCLUDE_CODE: guide/message_forwarder.bal -->

### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. To implement the scenario in this guide, you can use the following package structure:

```
  asynchronous-messaging
  |__guide
        |
        ├── http_message_receiver.bal
        └── message_forwarder.bal
```
 
- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to the guide directory, and run the Ballerina project initializing toolkit.

```bash
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Developing the service

1. First you need to implement `http_message_receiver.bal` which will listen for HTTP messages over port 9091 and publish it to ActiveMQ queue. 
2. Then you need to implement `message_forwarder.bal` which will listen on the same ActiveMQ queue, receive JMS message, convert it back to a Json message and invoke the HTTP Hospital service backend.  

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

### Deploying locally

To deploy locally, navigate to asynchronous-messaging/guide, and execute the following command.

```bash
  $ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services in the target folder. You can run this by using the `ballerina run` command.

```bash
  $ ballerina run <Exec_Archive_File_Name>
```

### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container. The Ballerina language includes a `Ballerina_Docker_Extension` that offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Since ActiveMQ is a prerequisite in this guide, there are a few more steps you need to follow to run the service you developed in a Docker container.

Navigate to [Docker Hub](https://hub.docker.com/r/webcenter/activemq) and follow the instructions. 

## Testing
Follow the steps below to invoke the service.

- On a new terminal, navigate to `<AMQ_HOME>/bin` and execute the following command to start the ActiveMQ server.

```bash
  $ ./activemq start
```

- Navigate to `asynchronous-messaging/guide` and execute the following two commands in two separate terminals to start each service.

```bash
  $ ballerina run http_message_receiver.bal
  $ ballerina run message_forwarder.bal
```

- Create a file called `input.json` with following JSON request to simulate placing doctor appointments.

```json
  {
    "patient": {
      "name": "John Doe",
      "dob": "1940-03-19",
      "ssn": "234-23-525",
      "address": "California",
      "phone": "8770586755",
      "email": "johndoe@gmail.com"
    },
    "doctor": "thomas collins",
    "hospital": "grand oak community hospital",
    "appointment_date": "2025-04-02"
  }
```

- Send the message using a curl command.

```bash
  curl -v -X POST --data @input.json http://localhost:9091/healthcare/make_appointment --header "Content-Type:application/json"
```

#### Output

You will see the following log, which confirms that the `http_message_receiver` service has sent the request to the ActiveMQ queue.

```bash
 New channel request added to the JMS queue; Patient: 'John Doe'
```

At the `message_forwarder` service you will see following log as the response from the healthcare service. 

```bash
Response is : {"appointmentNumber":4, "doctor":{"name":"thomas collins", "hospital":"grand oak community hospital", "category":"surgery", "availability":"9.00 a.m - 11.00 a.m", "fee":7000.0}, "patient":{"name":"John Doe", "dob":"1940-03-19", "ssn":"234-23-525", "address":"California", "phone":"8770586755", "email":"johndoe@gmail.com"}, "fee":7000.0, "confirmed":false, "appointmentDate":"2025-04-02"}
```

Navigate to ActiveMQ console (http://localhost:8161/admin/queues.jsp). Number of enqueued and dequeued messages of the queue `appointments` should be `1`. 
