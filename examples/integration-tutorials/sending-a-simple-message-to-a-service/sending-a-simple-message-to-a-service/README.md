# sending-a-simple-message-to-a-service

This guide demonstrates how to sending a simple message to a ballerina service. This service is basically implemented on real world scenario.Let’s start use case of Healthcare Management System.

## Backend

This implementation consist of one service with multiple resources.Each of these resources can be used for the testing of following Ballerina scenarios.
- POST medical appointments details.
- UPDATE appointments details.
- GET appointments details.
- DELETE appointments details.	

## Invoking the Service

What things you need to install the software and how to install them

```
ballerina run simple_service.bal
```

The service will be started and you will see the below output.

```
Initiating service(s) in 'simple_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```
## Testing

### Data Driven Testing

We can implement data driven tests by providing a function pointer as a data-provider. The function returns a value-set of data and you can iterate the same test over the returned data-set.

In this example we have implemented a simple_service which gets user input and provide a response as REST service.For simplicity, here use an in-memory map to keep all the appointments details. 

Following test cases have been implemented in simple_service_test.bal.

| Test Case ID| Test Case| Test Case Description| Status|
| ----------| --------| ----------| ------|
| TC001 | Verify the response when a valid HTTP POST request is sent.| **Given**:Healthcare Service should be up and running. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| TC002 | Verify the response when a valid HTTP POST request with space character is sent.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| TC003 | Verify the response when a valid HTTP POST request is sent as empty json object.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| TC004 | Verify the response when an valid ID is sent to update the details.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| TC005 | Verify the response when an valid ID is sent to retrieve the details.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| TC006 | Verify the response when an valid ID is sent to delete the details.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a valid payload. </br> **Then**:User should get a valid output.| Automated|
| NT001 | Verify the response when an invalid ID is sent to update the details.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a invalid ID. </br> **Then**:It should return an error as ID is invalid.| Automated|
| NT002 | Verify the response when an invalid ID is sent to retrieve the details.| **Given**:Healthcare Service should be up and running.. </br> **When**:A input should be sent to the service with a invalid ID. </br> **Then**:It should return an error as ID is invalid.| Automated|


## Running the tests

Navigate to the folder 'sending-a-simple-message-to-a-service' and run the tests as below.

```
ballerina test 
```

