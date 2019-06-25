# Sending a Simple Message to a Service

Let’s try a simple scenario where a patient makes an inquiry specifying the doctor's specialization (category) to retrieve a list of doctors that match the specialization. The required information is available in a backend
microservice written as a Ballerina service. We configure an API resource using Ballerina to receive the client request, instead of the client sending messages directly to the back-end service, thereby decoupling the client and the back-end service.

#### What you will build

In this tutorial, we will build a service using Ballerina to connect with the backend of the Health Care System. We will add a resource that will receive a client's request and retrieve the registered doctors from the backend service.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relavant to your OS.
  We will call the installed directory as BALLERINA_HOME.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).

#### Getting Started

This tutorial includes the following sections.

- [Creating the RESTful service](#creating-the-restful-service)
- [Creating the resource that handles the GET requests](#creating-the-resource-that-handles-the-get-requests)
- [Creating the client to connect to the backend of Health Care System](#creating-the-client-to-connect-to-the-backend-of-health-care-system)
- [Handling the response from the backend](#handling-the-response-from-the-backend)
- [Starting the backend service](#starting-the-backend-service)
- [Starting the RESTful service](#starting-the-restful-service)
- [Invoking the RESTful service](#invoking-the-restful-service)

<!--This implementation consists of one service with multiple resources. Each of these resources can be used for the testing of following Ballerina scenarios.

- POST medical appointment details.
- UPDATE appointments details.
- GET appointments details.
- DELETE appointments details.-->

#### Creating the Project Structure

Ballerina is a complete programming language that supports custom project structures. We will use the following package structure for this guide.

```
  └──sending-a-simple-message-to-a-service
    ├── guide
    |   ├── health_care_service.bal
    └── test
        └── health_care_service_test.bal
```

Create the above directories in your local machine and create the empty .bal files as mentioned.

Then open the terminal and navigate to _sending-a-simple-message-to-a-service_ directory. Run the following command to initialize a Ballerina project.

```
$ ballerina init
```

#### Creating the RESTful service

We first create a listener to listen to requests to the RESTful service.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

Then we add the service which listens for requests using the above listener on port 9090.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_2 } -->

#### Creating the resource that handles the GET requests

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

#### Starting the backend service

We have completed the service and resource needed to get the list of doctors from backend. To test this service, first we have to start the Health Care System backend as below.

```
$ ballerina run backend.balx
```

#### Starting the RESTful service

Now, we should start the RESTful service as below.

```
$ ballerina run health_care_service.bal
```

The service will be started and you will see the below output.

```
$ Initiating service(s) in 'health_care_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```

#### Invoking the RESTful Service

Let us invoke the REST service endpoint we just created.

```
$ curl -v http://localhost:9090/healthcare/querydoctor/surgery
```

You will see the response message from the _HealthcareService_ with a list of available doctors and the relevant details.

```
[{"name":"thomas collins",
  "hospital":"grand oak community hospital",
  "category":"surgery",
  "availability":"9.00 a.m - 11.00 a.m",
  "fee":7000.0},
 {"name":"anne clement",
  "hospital":"clemency medical center",
  "category":"surgery",
  "availability":"8.00 a.m - 10.00 a.m",
  "fee":12000.0},
 {"name":"seth mears",
  "hospital":"pine valley community hospital",
  "category":"surgery",
  "availability":"3.00 p.m - 5.00 p.m",
  "fee":8000.0}]
```

#### Data Driven Testing

We can implement data driven tests by providing a function pointer as a data-provider. The function returns a value-set of data and you can iterate the same test over the returned data-set.

In this example we have implemented a health_care_service which gets user input and provide a response as REST service.For simplicity, here use an in-memory map to keep all the appointments details.

Following test cases have been implemented in health_care_service_test.bal.

| Test Case ID | Test Case                                                                        | Test Case Description                                                                                                                                                                      | Status    |
| ------------ | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| TC001        | Verify the response when a valid HTTP POST request is sent.                      | **Given**:Healthcare Service should be up and running. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.           | Automated |
| TC002        | Verify the response when a valid HTTP POST request with space character is sent. | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.          | Automated |
| TC003        | Verify the response when a valid HTTP POST request is sent as empty json object. | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.          | Automated |
| TC004        | Verify the response when an valid ID is sent to update the details.              | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.          | Automated |
| TC005        | Verify the response when an valid ID is sent to retrieve the details.            | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.          | Automated |
| TC006        | Verify the response when an valid ID is sent to delete the details.              | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.          | Automated |
| NT001        | Verify the response when an invalid ID is sent to update the details.            | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a invalid ID. </br> **Then**:It should return an error as ID is invalid. | Automated |
| NT002        | Verify the response when an invalid ID is sent to retrieve the details.          | **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a invalid ID. </br> **Then**:It should return an error as ID is invalid. | Automated |

**Running the tests**

Navigate to the folder 'sending-a-simple-message-to-a-service' and run the tests as below.

```
$ ballerina test
```
