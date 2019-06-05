# Sending-a-simple-message-to-a-service

In this example, we are going to send a message input to a service which will output as an enhanced greeting. 

## Backend
The backend has been implemented to accept user input and provide an output message. 

## Developement
It is implemented a service as 'hello' which has the function as sayHello. As an exmaple, if user provides an input as 'John', it will send the response to the client as 'Hello John'. 

## Invoking the Service
 Navigate to the folder 'sending-a-simple-message-to-a-service' and start the 'hello service.'
 ```
ballerina run hello_service
 ```

 The service will be started and you will see the below output. 
 ```
 Initiating service(s) in 'hello_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```

Invoke the service as below. 
```
curl http://localhost:9090/hello/sayHello -d "John K"
```
  
## Running the tests
Navigate to the folder 'sending-a-simple-message-to-a-service' and run the tests as below. 
```
ballerina test
```
