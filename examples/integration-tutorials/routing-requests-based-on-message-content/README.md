# Routing Requests Based on Message Content

In the [Sending a Simple Message to a Service](../../sending-a-simple-message-to-a-service/sending-a-simple-message-to-a-service/) tutorial, we routed a simple message to a single endpoint in the backend service.
In this tutorial, we are building a service that can route a message to the relevant endpoint in backend,
depending on the content of the message payload.

#### What you will build

Using the Health Care System backend we have, we can schedule appointments in different hospitals.

When a user sends the appointment scheduling request to the Ballerina service _hospitalMgtService_, the message payload contains the name of the hospital where the appointment should be confirmed. Based on the hospital name sent in the request message, our Ballerina service should route the appointment reservation to the relevant hospital's back-end service.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).

### Let's Get Started!

> If you want to skip the basics and move directly to testing the implementation, you can clone the project from Github and skip to the [Testing](#testing) instructions.

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Creating the Resource to handle appointment reservation requests](#creating-the-resource-to-handle-appointment-reservation-requests)
  - [Routing requests to different hospitals](#routing-requests-to-different-hospitals)
- [Deploying the Service](#deploying-the-service)
- [Testing the Implementation](#testing-the-implementation)

### Implementation

#### Creating the Resource to handle appointment reservation requests

In the previous tutorial [Sending a Simple Message to a Service](../../sending-a-simple-message-to-a-service/sending-a-simple-message-to-a-service/), we implemented a Ballerina service **hospitalMgtService** with a resource to handle requests from clients to the Health Care backend. For this tutorial, we add another resource to route requests to different hospitals.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

#### Routing requests to different hospitals

Then, we can include the implementation for the endpoint exposed by the resource in the previous step. When a client reqeust reaches the endpoint, we will retrieve the hospital name from the payload, and send the request to the corresponding endpoint in the backend.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_2 } -->

### Deploying the Service

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying locally

To deploy locally, navigate to *routing-requests-based-on-message-content/guide*, and execute the following command.

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

### Testing the Implementation

#### Starting the backend service

We have completed the resource needed to add appointments at different hospitals. To test this service, first we have to start the previously downloaded Health Care System backend as below.

```
$ ballerina run backend.balx
```

#### Starting the RESTful service

Navigate to *routing-requests-based-on-message-content/guide* and start the RESTful service as below.

```
$ ballerina run health_care_service.bal
```

The service will be started and you will see the below output.

```
$ Initiating service(s) in 'health_care_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9092
```

#### Invoking the RESTful service

Use the request message file _request.json_ located in *routing-requests-based-on-message-content/resources* to invoke the service.

**request.json**

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

Navigate to *routing-requests-based-on-message-content/resources* and send the request message to the service using cURL.

```
$ curl -v -X POST --data @request.json http://localhost:9092/hospitalMgtService/categories/surgery/reserve --header "Content-Type:application/json"
```

You will get the following response with the appointment details.

```json
{
  "appointmentNumber": 1,
  "doctor": {
    "name": "thomas collins",
    "hospital": "grand oak community hospital",
    "category": "surgery",
    "availability": "9.00 a.m - 11.00 a.m",
    "fee": 7000.0
  },
  "patient": {
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com"
  },
  "fee": 7000.0,
  "confirmed": false,
  "appointmentDate": "2025-04-02"
}
```

> *appointmentNumber* would start from 1 and increment for each response by 1.
