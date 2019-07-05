# Exposing Several Services as a Single Service

In this tutorial, we are going to integrate many service calls and expose as a single service. This is commonly referred to as Service Chaining, where several services are integrated based on some business logic and exposed as a single, aggregated service.

#### What you will build

In the [Transforming Message Content](../../transforming-message-content/transforming-message-content/) tutorial, we sent a transformed appointment request to the backend of the Health Care System to schedule an appointment for a user. In this tutorial, we will invoke several endpoints in the backend to create an appointment, do the payment and send the confirmation back to the user.

We will use the same Health Care service used in previous steps as the backend for this example. This Health Care Service exposes various services such as making a medical appointment, viewing appointment details and viewing the doctors' details. We will combine two of such services, making an appointment and settling the payment for the appointment, and expose them as a single service using Ballerina.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).
- If you did not try the [Transforming Message Content](../../transforming-message-content/transforming-message-content/) tutorial yet, you can clone the project from GitHub and follow the steps as mentioned below.

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Scheduling an appointment](#scheduling-an-appointment)
  - [Adding payment for the appointment](#adding-payment-for-the-appointment)
  - [Sending response back to client](#sending-response-back-to-client)
- [Deploying the Service](#deploying-the-service)
- [Testing the Implementation](#testing-the-implementation)

### Implementation

#### Scheduling an appointment

In the previous tutorial, we called the backend service from the add appointment resource itself. Since we are chaining two services in this example, we will add a util function to handle scheduling appointments at the backend.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

When the client request is received, we check if the request payload is json. If so, we transform it to the format expected by the backend. Then we invoke the util function to add an appointment within the resource function.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_2 } -->

#### Adding payment for the appointment

After invoking the appointment scheduling endpoint, we get the first response and check if it is an actual appointment confirmation response. If not, we simply throw an error. If it is a valid response, we call the function that invokes the payment settlement request.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_3 } -->

#### Sending response back to client

Finally we get the response from payment endpoint and send it back to the user. We throw errors if the backend response or the original request payload are not in a valid format.

### Deploying the Service

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying Locally

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

Let's start the service by navigating to the folder *guide/health_care_service.bal* file is and executing the following command.

```
$ ballerina run health_care_service.bal
```

The 'hospitalMgtService' service will start on port 9092. Now we can send an HTTP request to this service.

Let's create a file called _request.json_ and add the following content.

```json
{
  "name": "John Doe",
  "dob": "1940-03-19",
  "ssn": "234-23-523",
  "address": "California",
  "phone": "8770586755",
  "email": "johndoe@gmail.com",
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital",
  "cardNo": "7844481124110331",
  "appointment_date": "2025-04-02"
}
```

And issue a curl request as follows.

```
$ curl -v http://localhost:9092/hospitalMgtService/categories/surgery/reserve -H 'Content-Type:application/json' --data @request.json '
```

Following will be a sample response of a succesful appointment reservation.

```json
{
  "appointmentNo": 1,
  "doctorName": "thomas collins",
  "patient": "John Doe",
  "actualFee": 7000.0,
  "discount": 20,
  "discounted": 5600.0,
  "paymentID": "b7981676-c1ca-4380-bc31-1725eb121d1a",
  "status": "Settled"
}
```
