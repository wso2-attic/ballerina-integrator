# Storing and Forwarding Messages

Storing and forwarding messages is used for serving traffic to back-end services that can accept request messages only 
at a given rate. As each received request is stored in the message store, it ensures guaranteed delivery of a message, 
making them available for future reference as well. 

This example demonstrates how we can forward a message to an HTTP endpoint in a reliable manner. It uses *messageStore*
connector module of Ballerina Integrator of EI, to store message and forward it to an HTTP endpoint with required resiliency measures. 

#### What you will build

In the previous [Exposing Several Services as a Single Service](../../exposing-several-services-as-a-single-service/exposing-several-services-as-a-single-service) tutorial, we invoked several endpoints in the Health 
Care System backend to create medical appointments. In this tutorial, we will add more reliability to the function of 
creating appointments using the message storing and forwarding pattern. 

We will use the same Health Care service used in previous steps as the backend for this example. When scheduling 
appointments using this system, it needs to process appointment requests in a reliable manner. However, this HTTP 
backend service which exposes the doctor channeling facility is not reliable, as it is a legacy system that is 
hosted in a different network. Thus, sometimes there can be network issues when reaching the service. Owing to the service
being legacy, it cannot process a lot of requests in parallel as well. Therefore, requests coming into this backend 
service should be regulated carefully. 

It is evident that we cannot expose the service directly to the users given the nature of the service. Thus,
we need to add reliability to the service using **store-and-forward** pattern. 

Messages reaching the backend endpoint will be stored in a **message store** reliably, which is an **ActiveMQ** queue 
instance. Then **message processor** will pick them up and forward to the backend service. Message is removed from the 
queue, only when the forwarding is successful. 

The following diagram illustrates the scenario:

![Tutorial Image](https://user-images.githubusercontent.com/4967046/60750183-706a5780-9fc2-11e9-9db6-bb4266640672.png)

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- [Apache ActiveMQ](http://activemq.apache.org/getting-started.html)
 * After you install ActiveMQ, copy the .jar files from the **<AMQ_HOME>/lib** directory to the **<BALLERINA_HOME>/bre/lib** directory.
 * If you use ActiveMQ version 5.12.0, you only have to copy *activemq-client-5.12.0.jar*, *geronimo-j2ee-management_1.1_spec-1.0.1.jar*, and *hawtbuf-1.11.jar* from the *<AMQ_HOME>/lib* directory to the *<BALLERINA_HOME>/bre/lib* directory.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Creating the project structure](#creating-the-project-structure)
  - [Developing the Message Storing Service](#developing-the-message-storing-service)
  - [Developing the Message Forwarding Service](#developing-the-message-forwarding-service)
- [Deploying the Service](#deploying-the-service)
- [Testing the Implementation](#testing-the-implementation)

### Implementation

> If you want to skip the basics and move directly to the [Testing the Implementation](#testing-the-implementation) section, you can download the project from 
Github and skip the [Implementation](#implementation) instructions.

#### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. To implement the scenario in this 
guide, you can use the following package structure:

```
  storing-and-forwarding-messages
  |__guide
        |
        ├── message_storing_service.bal
        └── reliable_message_forwarder.bal
```

Create the above directories in your local machine and also create the empty .bal files.
Then open a terminal, navigate to the *guide* directory, and run the Ballerina project initializing toolkit.

```bash
  $ ballerina init
```

Now that you have created the project structure, the next step is to develop the services.

#### Developing the Message Storing Service

To develop the message storing service, we will make use of the *message-store* connector module of WSO2 Ballerina Integrator in EI. 
In the **message_storing_service.bal** file created above, we can import the module to begin with the implementation. 

```ballerina
import wso2/messageStore;
```

Now we can create the message store clients to store messages sent to the backend endpoint. We will use ActiveMQ 
as our message broker service. We will also add a fail-over message store to handle storing of messages which failed 
to be saved in the primary message store. 

<!-- INCLUDE_CODE_SEGMENT: { file: guide/message_storing_service.bal, segment: segment_1 } -->

Then we will modify the appointment scheduling function, by adding the capability to store the messages received at 
the appointment scheduling endpoint. 

<!-- INCLUDE_CODE_SEGMENT: { file: guide/message_storing_service.bal, segment: segment_2 } -->

When this service is running, it will listen for HTTP messages to schedule medical appointments on port 9092, and store the received requests 
in the message store which we configured earlier. 

#### Developing the Message Forwarding Service

Now, we will develop the service which will get the messages from the Message Store and forward them over to the backend of the Health care System. 

In the **reliable_message_forwarder.bal** file, we will first create a reference to the message store which stores 
the messages as defined in the message storing service.  

<!-- INCLUDE_CODE_SEGMENT: { file: guide/reliable_message_forwarder.bal, segment: segment_1 } -->

Then we can create the Message Processor. We will also create a *DLCStore* to add the messages which fail to be forwarded to the 
HTTP endpoint. When the messages fail to be forwarded to the backend, the message would be stored in the DLCStore, 
and the forwarding service will continue with the next message.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/reliable_message_forwarder.bal, segment: segment_2 } -->

Now we can define the Message Processor and start it. 

<!-- INCLUDE_CODE_SEGMENT: { file: guide/reliable_message_forwarder.bal, segment: segment_3 } -->

When this service is running, it will listen to messages on the Message Store and forward them to the backend of the Health care System. 

### Deploying the Service

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying Locally

To deploy locally, navigate to *storing-and-forwarding-messages/guide*, and execute the following command.

```bash
$ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services in the target folder. 
You can run them by,

```bash
$ ballerina run <Exec_Archive_File_Name>
```

#### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container. The Ballerina language includes a 
Ballerina_Docker_Extension, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Since ActiveMQ is a prerequisite in this guide, there are a few more steps you need to follow to run the service you developed in a Docker container.
Please navigate to [dockerhub](https://hub.docker.com/r/webcenter/activemq) and follow the instructions. 

### Testing the implementation

Follow the steps below to invoke the service.

- Start the backend of previously downloaded *Healthcare service* by running the below command.

```bash
$ ballerina run healthcare.balx
```

- On a new terminal, navigate to *<AMQ_HOME>/bin*, and execute the following command to start the ActiveMQ server.

```bash
$ ./activemq start
```

- Navigate to *storing-and-forwarding-messages/guide*, and execute the following two commands in two separate terminals to start each service.

```bash
$ ballerina run message_storing_service.bal
$ ballerina run reliable_message_forwarder.bal 
```

- Create a file called input.json with following json request to simulate placing medical appointments.

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

- Send the message using curl.

```bash
curl -v -X POST --data @input.json http://localhost:9092/hospitalMgtService/categories/surgery/reserve --header "Content-Type:application/json"
```

- You will receive a response with HTTP Status code *202*. 

```bash
2019-07-05 17:34:22,387 INFO  [] - Response received Response status code= 200: {"appointmentNumber":1, "doctor":{"name":"thomas collins", "hospital":"grand oak community hospital", "category":"surgery", "availability":"9.00 a.m - 11.00 a.m", "fee":7000.0}, "patient":{"name":"John Doe", "dob":"1940-03-19", "ssn":"234-23-525", "address":"California", "phone":"8770586755", "email":"johndoe@gmail.com"}, "fee":7000.0, "confirmed":false, "appointmentDate":"2025-04-02"}
```

- In this example, retry configuration for the message processor is as follows. 

```ballerina
//forwarding retry 
retryInterval: 3000,
retryHTTPStatusCodes:[500,400],
maxRedeliveryAttempts: 5
```
  
To test reliable delivery, shutdown *healthcare service* and send the above curl message. Message processor will try to 
deliver the message five times and then route it to DLC store. You will see following log message and message is forwarded
to DLC Store. You can check the message count of queue *myDLCStore* using ActiveMQ console.  

```bash
2019-07-05 17:42:40,877 WARN  [wso2/messageStore] - Maximum retires breached when forwarding message to HTTP endpoint http://localhost:9090/grandoaks/categories/surgery/reserve. Forwarding message to DLC Store
``` 

If you restart the Health care service within 15 seconds, message will be delivered to the service and you will get the response with the HTTP Status code 202. 
