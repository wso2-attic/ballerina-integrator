# Service Composition

A service composition is an aggregate of services collectively composed to automate a particular task or business process. 

> This guide walks you through the process of implementing a service composition using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
  - [Creating the project structure](#Creating-the-project-structure)
  - [Developing the service](#Developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)
  - [Deploying locally](#Deploying-locally)

## What you’ll build
To understand how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the Travel agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/docs/content/resources/service-composition.svg)

Travel agency is the service that acts as the composition initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping `Implementation` section.

### Create the project structure

1. Create a new project `service-composition`.

    ```bash
    $ ballerina new  service-composition
    ```

2. Create a module named `guide` inside the project directory.

    ```bash
    $ ballerina add guide
    ```

Use the following module structure for this guide.

```
service-composition
├── Ballerina.toml
└── src
   └── guide
      ├── airline_reservation_service.bal
      ├── car_rental_service.bal
      ├── hotel_reservation_service.bal
      ├── travel_agency_service.bal
      ├── Module.md
      └── tests
          └── travel_agency_service_test.bal
```

Create the above directories in your local machine and copy the below given `.bal` files to appropriate locations.

### Developing the service

Let's look at the implementation of the travel agency service, which acts as the composition initiator.

Arranging a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:
```bash
{"Name":"Bob", "ArrivalDate":"12-03-2020", "DepartureDate":"13-04-2022", 
 "Preference":<service_dependent_preference>};
```

Sample response payload:

```bash
{"Status":"Success"}
```

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to book a flight ticket. To check the implementation of airline reservation service, see the `airline_reservation_service.bal` implementation.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. To check the implementation of hotel reservation service, see the `hotel_reservation_service.bal` implementation.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. To check the implementation of car rental service, see the `car_rental_service.bal` implementation.

If all services work successfully, the travel agency service confirms and arrange the complete tour for the user. Refer to the `travel_agency_service.bal` to see the complete implementation of the travel agency service. Inline comments are added for better understanding.


**travel_agency_service.bal**
<!-- INCLUDE_CODE: src/guide/travel_agency_service.bal -->

As shown above, the travel agency service rents a car for the requested user by calling the car rental service. `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

## Testing 

### Invoking the service

- Navigate to `service-composition` and run the following command to start all four HTTP services. This starts the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services on ports 9091, 9092, 9093 and 9090 respectively.

```bash
   $ ballerina run guide
```
   
- Invoke the travel agency service by sending a POST request to arrange a tour.

```bash
   curl -v -X POST -d '{"Name":"Bob", "ArrivalDate":"12-03-2020",
   "DepartureDate":"13-04-2022", "Preference":{"Airline":"Business",
   "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```

  Travel agency service sends a response similar to the following:
    
```bash
   < HTTP/1.1 200 OK
   {"Message":"Congratulations! Your journey is ready!!"}
``` 

## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally

- To deploy locally, navigate to `service-composition` directory, and execute the following command.
```bash
   $ ballerina build guide
```

- This builds a JAR file (.jar) in the target folder. You can run this by using the `java -jar` command.
```bash
  $ java -jar target/bin/guide.jar
```

- You can see the travel agency service and related backend services are up and running. The successful startup of services will display the following output. 
```
   [ballerina/http] started HTTP/WS listener 0.0.0.0:9091
   [ballerina/http] started HTTP/WS listener 0.0.0.0:9093
   [ballerina/http] started HTTP/WS listener 0.0.0.0:9092
   [ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```
