# Reliable message delivery 

This guide describes how to use `MessageStore` module to achieve reliable message delivery. In asynchronous messaging
scenarios we accept HTTP message and store it in a remote `message broker` for later processing. When the message forwarder
picks the message from the `message broker` and try to forward it to the intended HTTP service, that service may be not 
available at that moment, or it may respond with `500 (internal server error)`. In that case, the message should be retried again to deliver.
Only upon successful message delivery, the message will be removed from the queue. Otherwise, after several retries, message 
forwarder can stop or backup the message to a different (Deal Letter Store) store and continue with the next message.

Above is called `reliable message delivery`. However, there are other use-cases you can achieve using `MessageStore` module.

1. `in-order message delivery` : if only one message processor is picking message from the particular store, 
   in-order message delivery pattern is also achieved. Messages are delivered to the endpoint in a reliable manner keeping
   the order of the messages they were put to the store. 

2. `throttling` : consider a legacy backend which can process messages up to 100 TPS only. This service is exposed to a system
   from which it gets message bursts sometimes exceeding its limit of 100 TPS. To regulate the load we can use message store and 
   forward. System can store the message to the store in the speed it likes and message processor will forward the messages to
   the backend in a regulated way with its defined polling interval. 

In this guide we focus on `reliable message delivery`. 

The high level sections of this guide are as follows:

- [Reliable message delivery ](#Reliable-message-delivery)
  - [What you'll build](#What-youll-build)
  - [Prerequisites](#Prerequisites)
  - [Implementation](#Implementation)
    - [Setting up backend service](#Setting-up-backend-service)
    - [Creating the project structure](#Creating-the-project-structure)
    - [Developing message storing service](#Developing-message-storing-service)
    - [Developing message forwarding service](#Developing-message-forwarding-service)
  - [Deployment](#Deployment)
    - [Deploying locally](#Deploying-locally)
    - [Deploying on Docker](#Deploying-on-Docker)
  - [Testing](#Testing)
      - [Happy path scenario](#Happy-Path-Scenario)
      - [Backend returns error scenario](#Backend-returns-error-scenario)
      - [Backend not available scenario](#Backend-not-available-scenario)
      - [Deactivate message processor on forwarding failure](#Deactivate-message-processor-on-forwarding-failure)



## What you'll build

Let's consider a scenario where an incoming HTTP request is stored using `messageStore`. The message store is pointed
to a `queue` of `ActiveMQ` broker. The caller of the HTTP request will receive a HTTP accept `202` response if message
is stored successfully on the broker. Message forwarding task is initiated by another Ballerina service which polls messages
from the above store and invoke configured backend HTTP service. 

This backend service is a test service which will print headers and incoming message and response with a static payload. 

Upon receiving the response from the backend, user is allowed to perform any action upon the response as per the design 
of `messageStore` module. This action passed as an Lambda (function pointer) to the message processor when it is created. 
For simplicity, in this guide it will just log the response from the backend to the Ballerina log file. 

The following diagram illustrates the scenario in high level

![alt text](resources/message-store-processor-guide.svg)

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After you install ActiveMQ, copy the .jar files from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
   * If you use ActiveMQ version 5.12.0, you only have to copy `activemq-client-5.12.0.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar`, and `hawtbuf-1.11.jar` from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.

## Implementation

> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from 
git and skip the [Implementation](#implementation) instructions.


### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:

```bash
    reliable-delivery
        ├── guide
          ├── backend_service.bal
          ├── http_message_listener.bal
          └── message_forwarder.bal
```
     
- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to project directory and run the Ballerina init command.

```bash
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Setting up backend service

The backend service is exposing `/testservice/test` resource as a `POST` which accepts a Json message. It logs the incoming 
message payload with headers and return a static response. 

**backend_service.bal**
<!-- INCLUDE_CODE: guide/backend_service.bal-->

### Developing message storing service

This service will accept any incoming HTTP message and store it in `messageStore` defined. Note the following when configuring 
message store client. 

1. `MessageStoreConfiguration` is specified with required Message Broker detail when creating message store client. 
2. A fail-over store client is also defined and set to the primary message store client (optional). If message could not be forwarded
   to the primary store this store is used to store the message. 
3. `MessageStoreRetryConfig` is specifying resiliency parameters in case of message is not stored successfully. 

**http_message_listener.bal**
<!-- INCLUDE_CODE: guide/http_message_listener.bal-->


If message is successfully stored HTTP caller will get 202 accept message, or else `500-internal server error`. In this case
the caller is notified of successful message acceptance. 

### Developing message forwarding service 

When configuring `MessageForwardingProcessor`, there is a few things you need to consider. 
 
1. Same `MessageStoreConfiguration` you used to specify `messageStore` to store message in the above service should be
   used in `ForwardingProcessorConfiguration`. Notice in this example we are using the same pointing to the queue `myStore`.
2. You can specify in what speed message polling should be done or specify a cron. Here we configure it to poll a message 
   once 2 seconds going by cron expression `0/2 * * * * ?`. You can leverage this to run the processor at a specified time
   of the day etc.  
3. You can configure message processor to retry forwarding the messages it polls from the broker. In this example, message will 
   retry `5 times` with an interval of `3 seconds` between each retry. If backend responded with `500` or `400` status codes 
   processor will consider them as failed to forward messages. 
4. Once all retries to forward the message to the backend, you can either stop the message processor or drop the message and 
   continue. Optionally, if a DLC store (another messageStore) is configured message will be forwarded to it and processor 
   will move to the next message. In this example, we have specified a DLC store. 
5. In case of connection failure to the message broker, message processor will retry to regain the connection and initialize
   message consumer back. You also have the freedom to configure that retry. In here, once for every `15 seconds` it will try
   to connect to the broker. 
6. Once created, you need to `start` the processor for it to start running. 


Also notice that in the example we have exit the service in any case where it failed to initialize message processor (i.e 
connection establishment failed for the broker). 

**message_forwarder.bal**
<!-- INCLUDE_CODE: guide/message_forwarder.bal-->
 

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

To deploy locally, navigate to reliable-delivery/guide, and execute the following command.

```bash
$ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder. 
You can run them by 

```bash
$ ballerina run <Exec_Archive_File_Name>
```

### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container.The Ballerina language includes a Ballerina_Docker_Extension, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Since ActiveMQ is a prerequisite in this guide, there are a few more steps you need to follow to run the service you developed in a Docker container. Please navigate to [ActiveMQ on Dockerhub](https://hub.docker.com/r/webcenter/activemq) and follow the instructions.


## Testing

Follow below steps below to test out the reliable message delivery functionality using the services we developed above.

- On a new terminal, navigate to `<AMQ_HOME>/bin`, and execute the following command to start the ActiveMQ server.
```bash
    $ ./activemq start
```
### Happy path scenario

- Navigate to `reliable-delivery/guide`, and execute the following commands via separate terminals to start each service:
```bash
    $ ballerina run backend_service.bal
    $ ballerina run message-forwarder.bal
    $ ballerina run message-listener.bal
```
- Go to [ActiveMQ console](http://localhost:8161/admin/queues.jsp), and notice that there is one subscriber for queue `myStore`. 
- Send a message using curl to the HTTP service exposed by `http_message_listener` service like below. File `input.json` can 
  have any valid json message. 
    ```bash
    curl -v -X POST --data @input.json http://localhost:9091/healthcare/appointment --header "Content-Type:application/json" --header "Company:WSO2"
    ```
- Notice that curl got a HTTP response with 202 status code.
    ```
    < HTTP/1.1 202 Accepted
    < content-length: 0
    < server: ballerina/0.991.0
    < date: Tue, 2 Jul 2019 18:09:56 +0530
    ```
- Notice in the backend server log incoming request is logged as below, with custom headers included. 
    ```
    2019-07-02 18:09:56,374 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095]
    ```
- Notice that at message_forwarder logic to handle response is executed. 
    ```
    2019-07-02 18:20:50,186 INFO  [wso2/messageStore] - Response received Response status code= 200: {"Message":"This is Test Service"}
    ```
- Notice that the message is removed from the queue and message count is zero. 


### Backend returns an error scenario

- Shutdown `message_forwarder.bal` and `backend_service.bal` services. 
- Modify `backend_service.bal` service to return `500` HTTP status code always. 
  ```
  response.statusCode = 500;
  ```
- Start back the service and `message_forwarder.bal`
- Send the same curl message above. You will notice message processor is trying to deliver it 5 times observing the log at
  backend service. 
  ```
    2019-07-02 18:24:38,119 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
    2019-07-02 18:24:41,301 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
    2019-07-02 18:24:44,317 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
    2019-07-02 18:24:47,330 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
    2019-07-02 18:24:50,340 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
    2019-07-02 18:24:53,352 INFO  [] - HIT!! - payload = {"Status":"SUCCESS"}Headers = [Accept: */*] , [Company: WSO2] , [connection: keep-alive] , [content-length: 27] , [Content-Type: application/json] , [host: 127.0.0.1:9095] ,
  ```
- Then message processor will forward the filing message to DLC store specified. navigate to [ActiveMQ console](http://localhost:8161/admin/queues.jsp)
  and notice there is one message in the queue `myDLCStore`. 
  ```
    2019-07-02 18:24:53,356 WARN  [wso2/messageStore] - Maximum retires breached when forwarding message to HTTP endpoint http://127.0.0.1:9095/testservice/test. Forwarding message to DLC Store
  ```

### Backend not available scenario

- Shutdown `backend_service.bal` service.
- Send the curl message again.
- Notice that message processor is trying to forward the message and then give up. 
- Message will be moved to store `myDLCStore` same as in above step. 
  ```
  2019-07-02 18:27:35,034 WARN  [wso2/messageStore] - Maximum retires breached when forwarding message to HTTP endpoint http://127.0.0.1:9095/testservice/test. Forwarding message to DLC Store
  ```
### Deactivate message processor on forwarding failure

- In `message_forwarder.bal` edit the `ForwardingProcessorConfiguration` config as `deactivateOnFail: true`. 
- Send the curl message again.
- Notice that message processor is trying to forward the message and then give up.
- This time it will be stopped with following message
  ```
  2019-07-03 16:29:38,549 WARN  [wso2/messageStore] - Maximum retires breached when forwarding message to HTTP endpoint http://127.0.0.1:9095/testservice/test. Message forwarding is stopped for http://127.0.0.1:9095/testservice/test
  2019-07-03 16:29:38,550 INFO  [wso2/messageStore] - Deactivating message processor on queue = myStore
  ```

Notice that message forwarding processor will behave upon forwarding failure in following priority order

1. If {`deactivateOnFail: true`} is configured it will be deactivated and message polling will stop. Message will remain on the store.
2. If {`DLCStore: dlcStoreClient`} is configured message will be routed to that queue pointed by that client and will be removed from 
   the original store. 
3. If no above is specified message processor will drop the message and pick the next message of the store to try.  
