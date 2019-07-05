# Transforming Message Content

When the message format sent by the client is diffrent from the format expected by the backend service, we need to transform the message into a supported format before sending the request to backend. Using Ballerina, we can easily transform messages to a desired format.

#### What you will build

In the [Routing Requests Based on Message Content](../../routing-requests-based-on-message-content/routing-requests-based-on-message-content/) tutorial, we sent requests to the backend to schedule appointments.

Let’s assume this is the format of the request sent by the client:

```json
{
  "name": "John Doe",
  "dob": "1940-03-19",
  "ssn": "234-23-525",
  "address": "California",
  "phone": "8770586755",
  "email": "johndoe@gmail.com",
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital",
  "cardNo": "7844481124110331",
  "appointment_date": "2017-04-02"
}
```

However, the format of the message required by the backend service is as follows:

```json
{
  "patient": {
    "name": "John Doe",
    "dob": "1990-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com"
    "cardNo": "7844481124110331"
  },
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital"
  "appointment_date": "2017-04-02"
}
```

The request payload message format must be transformed to match the back-end service message format.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).
- If you did not try the [Routing Requests Based on Message Content](../../routing-requests-based-on-message-content/routing-requests-based-on-message-content/) tutorial yet, you can clone the project from GitHub and follow the steps as mentioned below.

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Modify the resource to transform messages](#modify-the-resource-to-transform-messages)
- [Deploying the Service](#deploying-the-service)
- [Testing the Implementation](#testing-the-implementation)

### Implementation

#### Modify the resource to transform messages

In the RESTful service we developed earlier, we already have a resource to schedule appointments in the Health Care System. Let's modify this resource so that it can transform messages before sending requests to the backend.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

### Deploying the Service

You can deploy the above services in your local environment. First you can create the Ballerina executable archives (.balx) as follows.

Navigate to _transforming-message-content/guide_ and execute the following command to build the service.

```bash
$ ballerina build
```

After the build is successful, there will be a _.balx_ file inside the _target_ directory. You can then execute the _.balx_ file as follows.

```bash
$ ballerina run health_care_service.balx
```

### Testing the Implementation

- Navigate to _transforming-message-content/guide_, and execute the following command to start the service:

```bash
   $ ballerina run health_care_service.bal
```

- Create a file called input.json within _guide_ directory and add the following json request:

```json
{
  "name": "John Doe",
  "dob": "1940-03-19",
  "ssn": "234-23-525",
  "address": "California",
  "phone": "8770586755",
  "email": "johndoe@gmail.com",
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital",
  "cardNo": "7844481124110331",
  "appointment_date": "2025-04-02"
}
```

- Send the message to the service using curl

```bash
$ curl -v -X POST --data @input.json http://localhost:9092/hospitalMgtService/categories/surgery/reserve --header "Content-Type:application/json"
```

You will see the response as follows:

```json
{
  "appointmentNumber": 4,
  "doctor": {
    "name": "thomas collins",
    "hospital": "grand oak community hospital",
    "category": "surgery",
    "availability": "9.00 a.m - 11.00 a.m",
    "fee": 7000
  },
  "patient": {
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com"
  },
  "fee": 7000,
  "confirmed": false,
  "appointmentDate": "2017-04-02"
}
```
