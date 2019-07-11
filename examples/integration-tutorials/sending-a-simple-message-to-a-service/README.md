# Sending a Simple Message to a Service

Let’s try a simple scenario where a patient makes an inquiry specifying the doctor's specialization (category) to retrieve a list of doctors that match the specialization. The required information is available in a backend
microservice written as a Ballerina service. We configure an API resource using Ballerina to receive the client request, instead of the client sending messages directly to the back-end service, thereby decoupling the client and the back-end service.

#### What you will build

In this tutorial, we will build a service using Ballerina to connect with the backend of the Health Care System. We will add a resource that will receive a client's request and retrieve the registered doctors from the backend service.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
  We will call the installed directory as BALLERINA_HOME.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Creating the Project Structure](#creating-the-project-structure)
  - [Creating the RESTful service](#creating-the-restful-service)
  - [Creating the resource to handle GET requests](#creating-the-resource-to-handle-the-requests)
  - [Creating the client to connect to Health Care System backend](#creating-the-client-to-connect-to-health-care-system-backend)
  - [Handling the response from the backend](#handling-the-response-from-the-backend)
- [Deployment](#deployment)
  - [Deploying Locally](#deploying-locally)
  - [Deploying on Docker](#deploying-on-docker)
- [Testing](#testing)
  - [Starting the backend service](#starting-the-backend-service)
  - [Starting the RESTful service](#starting-the-restful-service)
  - [Invoking the RESTful service](#invoking-the-restful-service)

### Implementation

#### Creating the Project Structure

Ballerina is a complete programming language that supports custom project structures. We will use the following package structure for this guide.

```
  └──sending-a-simple-message-to-a-service
    └──guide
        └──health_care_service.bal
```

Create the above directories in your local machine and create the empty .bal files as mentioned.

Then open the terminal and navigate to *sending-a-simple-message-to-a-service* directory. Run the following command to initialize a Ballerina project.

```
$ ballerina init
```

#### Creating the RESTful service

We first create a listener to listen to requests to the RESTful service.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

Then we add the service which listens for requests using the above listener on port 9092.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_2 } -->

#### Creating the resource to handle GET requests

Now we can add resources to handle each request type to the service. In this sample, we will add a single resource to handle GET requests to the service.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_3 } -->

#### Creating the client to connect to the backend of Health Care System

Now we create an HTTP client to connect to the backend of the Health Care System.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_4 } -->

We can use this client to invoke the querydoctor endpoint of the backend and retrieve the list of doctors.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_5 } -->

#### Handling the response from the backend

Once a response is received, it has to be set to the outgoing response of the service.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_6 } -->

### Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying Locally

To deploy locally, navigate to _routing-requests-based-on-message-content/guide_, and execute the following command.

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

#### Starting the backend service

We have completed the service and resource needed to get the list of doctors from backend. To test this service, first we have to start the Health Care System backend as below.

```
$ ballerina run health-care-backend.balx
```

#### Starting the RESTful service

Now, we should start the RESTful service as below.

```
$ ballerina run health_care_service.bal
```

The service will be started and you will see the below output.

```
$ Initiating service(s) in 'health_care_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9092
```

#### Invoking the RESTful Service

Let us invoke the REST service endpoint we just created.

```
$ curl -v http://localhost:9092/hospitalMgtService/getdoctor/surgery
```

You will see the response message from the _HealthcareService_ with a list of available doctors and the relevant details.

```json
[
  {
    "name": "thomas collins",
    "hospital": "grand oak community hospital",
    "category": "surgery",
    "availability": "9.00 a.m - 11.00 a.m",
    "fee": 7000.0
  },
  {
    "name": "anne clement",
    "hospital": "clemency medical center",
    "category": "surgery",
    "availability": "8.00 a.m - 10.00 a.m",
    "fee": 12000.0
  },
  {
    "name": "seth mears",
    "hospital": "pine valley community hospital",
    "category": "surgery",
    "availability": "3.00 p.m - 5.00 p.m",
    "fee": 8000.0
  }
]
```
