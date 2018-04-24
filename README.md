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

- The Stock Quote Summary service will call the backend to get the stock data
- The Ballerina Stock Quote Summary service will call the backend 3 times asynchronously
- Finally, the Summary servie will send all the details from 3 backend calls to the client.
.

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



- **Request Stock Summary** : To reserve a seat you can use the HTTP POST message that contains the passanger details, which is sent to the URL `http://localhost:9090/airline/reservation`. 


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
messaging-with-ballerina
├── Ballerina.toml
├── guide.flight_booking_service
│   └── airline_resrvation.bal
└── guide.flight_booking_system
    └── flight_booking_system.bal

```
You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `restful-service` and navigate to the directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
restful-service$ ballerina init -i
Create Ballerina.toml [yes/y, no/n]: (y) y
Organization name: (username) messaging-with-ballerina
Version: (0.0.1) 
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) guide.flight_booking_service
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) guide.flight_booking_system
Ballerina source [service/s, main/m, finish/f]: (f) f

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change the names of the file to match with our guide project file names.
  
### Implement the Airline reservation web service with Ballerina message sender

- We can get started with the airline reservation service, which is the RESTful service that serves the flight booking request. This service will reveive the requests as HTTP POST method from the customers.

-  The service will extract the passenger details from the flight reservation request. The flight booking will then send to the flight booking system using messaging. 

- Ballerina message broker will be used as the message broker for this process. `endpoint mb:SimpleQueueSender queueSenderBooking` is the endpoint of the message queue sender for new bookings of flight. You can give the preferred configuration of the message broker and queue name inside the endpoint definition. We have used the default configurations for the ballerina message broker. `endpoint mb:SimpleQueueSender queueSenderCancelling` is the endpoint to send the messages for cancelling the reservations.
- We have maintained two seperate queues for manage the flight reservations and cancellations.

##### airline_resrvation.bal
```ballerina
import ballerina/mb;
import ballerina/log;
import ballerina/http;
import ballerina/io;

@Description {value:"Define the message queue endpoint for new bookings"}
endpoint mb:SimpleQueueSender queueSenderBooking {
    host:"localhost",
    port:5672,
    queueName:"NewBookingsQueue"
};

@Description {value:"Define the message queue endpoint for cancel bookings"}
endpoint mb:SimpleQueueSender queueSenderCancelling {
    host:"localhost",
    port:5672,
    queueName:"BookingCancellationQueue"
};

@Description {value:"Attributes associated with the service endpoint"}
endpoint http:Listener airlineReservationEP {
    port:9090
};

@Description {value:"Airline reservation service exposed via HTTP/1.1."}
@http:ServiceConfig {
    basePath:"/airline"
}
service<http:Service> airlineReservationService bind airlineReservationEP {
    @Description {value:"Resource for reserving seats on a flight"}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/reservation"
    }
    bookFlight(endpoint conn, http:Request req) {
        http:Response res = new;
        // Get the booking details from the request
        json requestMessage = check req.getJsonPayload();
        string booking = requestMessage.toString();

        // Create a message to send to the flight reservation system
        mb:Message message = check queueSenderBooking.createTextMessage(booking);
        // Send the message to the message queue
        var _ = queueSenderBooking -> send(message);

        // Set string payload as booking successful.
        res.setStringPayload("Your booking was successful");

        // Sends the response back to the client.
        _ = conn -> respond(res);
    }

    @Description {value:"Resource for cancelling already reserved seats on a flight"}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/cancellation"
    }
    cancelBooking(endpoint conn, http:Request req) {
        http:Response res = new;
        // Get the booking details from the request
        json requestMessage = check req.getJsonPayload();
        string cancelBooking = requestMessage.toString();

        // Create a message to send to the flight reservation system
        mb:Message message = check queueSenderCancelling.createTextMessage(cancelBooking);
        // Send the message to the message queue
        var _ = queueSenderCancelling -> send(message);

        // Set string payload as booking successful.
        res.setStringPayload("Your booking was successful");

        // Sends the response back to the client.
        _ = conn -> respond(res);
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
