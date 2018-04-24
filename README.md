# Asynchronous Invocations
[Asynchronous invocations](https://en.wikipedia.org/wiki/Asynchronous_method_invocation) or the asynchronous pattern is a design pattern in which the call site is not blocked while waiting for the called code to finish. Instead, the calling thread can use the result when the reply arrives.

> In this guide you will learn about building a web service with asynchronous RESTful calls. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build 

To understanding how you can use asynchronous invocations with Ballerina, let’s consider an Stock Quote Summary service.

- The Stock Quote Summary service will call a remote backend to get the stock data
- The Ballerina Stock Quote Summary service will call the remote backend for three separate endpoints asynchronously
- Finally, the quote summary servie will append all the results from three backend and send the responses to the client.

The following figure illustrates the scenario of the Stock Quote Summary service with asynchronous invocations. 


&nbsp;
&nbsp;
&nbsp;
&nbsp;

![async invocation](images/asynchronous-invocation.png "Asynchronous Invocation")

&nbsp;
&nbsp;
&nbsp;
&nbsp;



- **Request Stock Summary** : You can send HTTP GET request to the URL `http://localhost:9090/quote-summary` and retrieve the stock quote summary.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service 

> If you want to skip the basics, you can download the git repo and directly move to "Testing" section by skipping "Developing" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
asynchronous-invocation
  ├── asynchronous_invocation
  │   └── async_service.bal
  └── stock_quote_service
    └── stock_backend.bal
```
You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `asynchronous-invocation` and navigate to the directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
restful-service$ ballerina init -i
Create Ballerina.toml [yes/y, no/n]: (y) y
Organization name: (username) asynchronous-invocation
Version: (0.0.1) 
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) asynchronous_invocation
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) stock_quote_service
Ballerina source [service/s, main/m, finish/f]: (f) f

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change the names of the file to match with our guide project file names.
  
### Implement the stock quote summary service with asyncronous invocations

- We can get started with the stock quote summary service, which is the RESTful service that serves the stock quote summary requests. This service will reveive the requests as HTTP GET method from the clients.

-  The stock quote summary service will call three separate remote resorces asynchronously.

- The Ballerina language support function calls and client connector actions to execute asynchronously.`start` keyword allows you to invoke the function asychronously. The `future` type allows you to have the result in future. The program can proceed without any blocking after the asynchronous function invocation. The following statement will call the endpoint asynchronously.

  `future <http:Response|http:HttpConnectorError> f3 = start nasdaqServiceEP -> get("/nasdaq/quote/MSFT", request = req);`

- Finally, the service will append all three responses and return the stock quote summary to the client. For get the results from a asynchronous call we need to use keywork `await`. `await` blocks until the previously started asynchronous invocation.


##### async_service.bal
```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/runtime;

@Description {value:"Attributes associated with the service endpoint is defined here."}
endpoint http:Listener asyncServiceEP {
    port:9090
};

@Description {value:"Service is to be exposed via HTTP/1.1."}
@http:ServiceConfig {
    basePath:"/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {

    @Description {value:"Resource for the GET requests of quote service"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    getQuote(endpoint caller, http:Request req) {
        // Endpoint for the stock quote backend service
        endpoint http:Client nasdaqServiceEP {
            url:"http://localhost:9095"
        };
        http:Request req = new;
        http:Response resp = new;
        string responseStr;

        io:println(" >> Invoking services asynchrnounsly...");

        // 'start' allows you to invoke a functions  asynchronously. Following three
        // remote invocation returns without waiting for response.

        // Calling the backend to get the stock quote for GOOG asynchronously
        future <http:Response|http:HttpConnectorError> f1 = start nasdaqServiceEP
        -> get("/nasdaq/quote/GOOG", request = req);

        io:println(" >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for APPL asynchronously
        future <http:Response|http:HttpConnectorError> f2 = start nasdaqServiceEP
        -> get("/nasdaq/quote/APPL", request = req);

        io:println(" >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for MSFT asynchronously
        future <http:Response|http:HttpConnectorError> f3 = start nasdaqServiceEP
        -> get("/nasdaq/quote/MSFT", request = req);

        io:println(" >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.");

        // ‘await` blocks until the previously started async function returns.
        // Append the results from all the responses of stock data backend
        var response1 = check await f1;
        responseStr = check response1.getStringPayload();

        var response2 = check await f2;
        responseStr = responseStr + " \n " + check response2.getStringPayload();

        var response3 = check await f3;
        responseStr = responseStr + " \n " + check response3.getStringPayload();

        // Send the response back to the client
        resp.setStringPayload(responseStr);
        io:println(" >> Response : " + responseStr);
        _ = caller -> respond(resp);
    }
}
```

### Implement the Airline reservation system with Ballerina message receiver

- You can receive the messages from the flight reservation service through the Balleina message broker.

- You can define endpoints to reveive messages from Ballerina message queues. The `endpoint mb:SimpleQueueReceiver queueReceiverBooking` will be the endpoint for the messages from new flight reservations. The parameters inside the endpoint will used to connect with the Ballerina message broker. We have used the defaults values for this guide

- The `endpoint mb:SimpleQueueReceiver queueReceiverCancelling` is the endpoint for the message broker and queue for the cancellations of the flight reservations.

- You can have the Ballerina message listener service for each message queues. The message listener service for the new bookings is declared using `service<mb:Consumer> bookingListener bind queueReceiverBooking ` serivce. Inside the service we have the ` onMessage(endpoint consumer, mb:Message message)` resource which will trigger when a new message arrives for the defined queue. Inside the resoucrce we can handle the business logic that we want to proceed when a new flight booking order comes. For the guide we will print the message in the console.

- Similary we have `service<mb:Consumer> cancellingListener bind queueReceiverCancelling` service to handle flight reservation cancellation orders.

##### flight_booking_system.bal

```ballerina
import ballerina/mb;
import ballerina/log;

@description{value:"Queue receiver endpoint for new flight bookings"}
endpoint mb:SimpleQueueReceiver queueReceiverBooking {
    host:"localhost",
    port:5672,
    queueName:"NewBookingsQueue"
};

@description{value:"Queue receiver endpoint for cancellation of flight bookings"}
endpoint mb:SimpleQueueReceiver queueReceiverCancelling {
    host:"localhost",
    port:5672,
    queueName:"BookingCancellationQueue"
};

@description{value:"Service to receive messages for new booking message queue"}
service<mb:Consumer> bookingListener bind queueReceiverBooking {
    @description{value:"Resource handler for new messages from queue"}
    onMessage(endpoint consumer, mb:Message message) {
        // Get the new message as the string
        string messageText = check message.getTextMessageContent();
        // Mock the processing of the message for new booking
        log:printInfo("[NEW BOOKING] Details : " + messageText);
    }
}

@description{value:"Service to receive messages for booking cancellation message queue"}
service<mb:Consumer> cancellingListener bind queueReceiverCancelling {
    @description{value:"Resource handler for new messages from queue"}
    onMessage(endpoint consumer, mb:Message message) {
        // Get the new message as the string
        string messageText = check message.getTextMessageContent();
        // Mock the processing of the message for cancellation of bookings
        log:printInfo("[CANCEL BOOKING] : " + messageText);
    }
}
```


- With that we've completed the development of Airline reservation service with Ballerina messaging. 


## Testing 

### Invoking airline reservation service with ballerina message broker

- First, you need to run [Ballerina message broker](https://github.com/ballerina-platform/ballerina-message-broker). Follow the instruction on the Ballerina message broker Github repository setup the Ballerina message broker.
```
<BALLERINA_MESSAGE_BROKER>/bin$ ./broker.sh 
```

- Then, you need to run flight booking sytem(which listen to the message queues)`guide.flight_booking_system`. Open your terminal and navigate to `<SAMPLE_ROOT_DIRECTORY>/` and execute the following command.
```
$ballerina run guide.flight_booking_system/
```
NOTE: You need to have the Ballerina installed in you local machine to run the Ballerina service.  

- Then, you need to run flight booking service(which serves client requests throught HTTP REST calls)`guide.flight_booking_service`. Open your terminal and navigate to `<SAMPLE_ROOT_DIRECTORY>/` and execute the following command.
```
$ballerina run guide.flight_booking_service/
```
- Now you can execute the following curl commands to call the Airline reservation servie to reserve a seat in a flight

**Book a seat** 

```
 curl -v -X POST -d '{ "Name":"Alice", "SSN":123456789, "Address":"345,abc,def", \
 "Telephone":112233 }' "http://localhost:9090/airline/reservation" -H \
 "Content-Type:application/json"


Output :  
Your booking was successful
```

**Cancel Reservation** 
```
curl -v -X POST -d '{ "bookingID":"A32D"}' "http://localhost:9090/airline/cancellation"\
-H "Content-Type:application/json"

Output : 
You have successfully canceled your booking
```
- The `guide.flight_booking_system` is the system that process the messages send through the ballerina message broker. The following consol logs should be printed in your consol where you running the `guide.flight_booking_system`

```
2018-04-23 21:08:09,475 INFO  [guide.flight_booking_system] - [NEW BOOKING] Details :\
{"Name":"Alice","SSN":123456789,"Address":"345,abc,def","Telephone":112233} 

2018-04-23 21:10:59,439 INFO  [guide.flight_booking_system] - [CANCEL BOOKING] : \
{"bookingID":"AV323D"} 

```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'. The naming convention should be as follows,

* Test functions should contain test prefix.
  * e.g.: testResourceAddOrder()

To run the unit tests you run the following command.
```bash
   $ballerina test
```

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally

- As the first step you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory in which the service we developed above located and it will create an executable binary out of that. Navigate to the `<SAMPLE_ROOT>/` folder and run the following commands. 

```
$ballerina build guide.flight_booking_service
```

```
$ballerina build guide.flight_booking_system
```

- Once the guide.flight_booking_service.balx and guide.flight_booking_system.balx are created inside the target folder, you can run that with the following command. 

```
$ballerina run target/guide.flight_booking_service.balx
```

```
$ballerina run target/guide.flight_booking_system.balx
```

- The successful execution of the service should show us the following output. 
```
$ballerina run guide.ballerina_messaging/
ballerina: initiating service(s) in 'guide.ballerina_messaging'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

```
$ ballerina  run guide.flight_booking_system/
ballerina: initiating service(s) in 'guide.flight_booking_system'
2018-04-23 20:39:41,872 INFO  [ballerina.jms] - Message receiver created \
for queue NewBookingsQueue 
2018-04-23 20:39:41,905 INFO  [ballerina.jms] - Message receiver created \
for queue BookingCancellationQueue 

```
