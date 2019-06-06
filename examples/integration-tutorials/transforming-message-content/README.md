# Message Transformation

In this example, we are going to transform a request message payload to a different format expected by the back-end service.

The high level sections of this guide are as follows:

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Deployment](#deployment)
- [Testing](#testing)

## What you'll build
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
The request payload message format must be transformed to the back-end service message format.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

## Implementation

### Creating the module structure

Ballerina is a complete programming language that can have any custom project structure as you wish. Although the 
language allows you to have any module structure, you can use the following simple module structure for this project.

```
transforming-message-content
  ├── message_transformation_service
      └── tests
          └── message_transformation_test.bal
      └── message_transformation.bal
```

- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to message_transformation_service, and run the Ballerina project initializing toolkit.
   ```
   $ ballerina init
   ```
Now that you have created the project structure, the next step is to develop the service.

### Developing the service
Take a look at the message_transformation.bal file to understand how to implement the service. Here, this sample exposes a service named **makeReservation**, which converts the request payload to a different format required by the reservation service of the backend. And then make a call to the backend service and respond back to the client. 

## Deployment

#### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first as follows.

**Building**
Navigate to message_transformation_service and execute the following command.
```bash
$ ballerina build message_transformation_service
```

After the build is successful, there will be a message_transformation_service.balx file inside the target directory. You can execute it as follows.

```bash
$ ballerina run message_transformation_service.balx
```

## Testing

- Navigate to `message_transformation_service`, and execute the following command to start the service:

```ballerina
   $ ballerina run message_transformation.bal
```
- Create a file called input.json with following json request:

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
- Send the message using curl 
```
curl -v -X POST --data @input.json http://localhost:9091/healthcare/categories/surgery/reserve --header "Content-Type:application/json"
```
#### Output
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
