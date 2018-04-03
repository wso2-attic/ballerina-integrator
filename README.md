[![Build Status](https://travis-ci.org/pranavan15/service-composition.svg?branch=master)](https://travis-ci.org/pranavan15/service-composition)

# Service Composition

A service composition is an aggregate of services collectively composed to automate a particular task or business process. 

> This guide walks you through the process of implementing a service composition using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the service](#developing-service)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
- [Observability](#observability)

## <a name="what-you-build"></a>  What you’ll build
To understanding how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the Travel agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/images/service_composition.png)

Travel agency is the service that acts as the composition initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## <a name="developing-service"></a> Developing the service

### <a name="before-begin"></a> Before you begin
##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
service-composition
  └── src
      ├── AirlineReservation
      │   ├── airline_reservation_service.bal
      │   └── test
      │       └── airline_reservation_service_test.bal
      ├── CarRental
      │   ├── car_rental_service.bal
      │   └── test
      │       └── car_rental_service_test.bal
      ├── HotelReservation
      │   ├── hotel_reservation_service.bal
      │   └── test
      │       └── hotel_reservation_service_test.bal
      └── TravelAgency
          ├── test
          │   └── travel_agency_service_test.bal
          └── travel_agency_service.bal

```

Package `AirlineReservation` contains the service that provides online flight ticket reservations.

Package `CarRental` contains the service that provides online car rentals.

Package `HotelReservation` contains the service that provides online hotel room reservations.

The `travel_agency_service.bal` file provides travel agency service, which consumes the other three services, and arranges a complete tour for the requested user.


### <a name="Implementation"></a> Implementation

Let's look at the implementation of the travel agency service, which acts as the composition initiator.

Arranging a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:

```bash
{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "Preference":<service_dependent_preference>};
```

Sample response payload:

```bash
{"Status":"Success"}
```

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to book a flight ticket. To check the implementation of airline reservation service, see the [airline_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/AirlineReservation/airline_reservation_service.bal) file.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. To check the implementation of hotel reservation service, see the [hotel_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/HotelReservation/hotel_reservation_service.bal) file.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. To check the implementation of car rental service, see the [car_rental_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/CarRental/car_rental_service.bal) file.

If all services work successfully, the travel agency service confirms and arrange the complete tour for the user. The skeleton of `travel_agency_service.bal` file is attached below. Inline comments are added for better understanding.
Refer to the [travel_agency_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/TravelAgency/travel_agency_service.bal) to see the complete implementation of the travel agency service.

##### travel_agency_service.bal

```ballerina
package TravelAgency;

import ballerina/net.http;

// Service endpoint
endpoint http:ServiceEndpoint travelAgencyEP {
    port:9090
};

// Client endpoint to communicate with Airline reservation service
endpoint http:ClientEndpoint airlineReservationEP {
    targets:[{uri:"http://localhost:9091/airline"}]
};

// Client endpoint to communicate with Hotel reservation service
endpoint http:ClientEndpoint hotelReservationEP {
    targets:[{uri:"http://localhost:9092/hotel"}]
};

// Client endpoint to communicate with Car rental service
endpoint http:ClientEndpoint carRentalEP {
    targets:[{uri:"http://localhost:9093/car"}]
};

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {

    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    arrangeTour (endpoint client, http:Request inRequest) {
        http:Response outResponse = {};

        // JSON payload format for an HTTP OUT request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"", "Preference":""};

        // Try parsing the JSON payload from the user request

        // If payload parsing fails, send a "Bad Request" message as the response

        // Reserve airline ticket for the user by calling the airline reservation service

        // Reserve hotel room for the user by calling the hotel reservation service

        // Renting car for the user by calling the car rental service
        
        
        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        _ = client -> respond(outResponse);
    }
}

```

Let's now look at the code segment that is responsible for communicating with the airline reservation service. 

```ballerina
// Reserve airline ticket for the user by calling Airline reservation service
http:Request outReqAirline = {};
http:Response inResAirline = {};
// construct the payload
json outReqPayloadAirline = outReqPayload;
outReqPayloadAirline.Preference = airlinePreference;
outReqAirline.setJsonPayload(outReqPayloadAirline);

// Send a post request to airlineReservationService with appropriate payload and get response
inResAirline =? airlineReservationEP -> post("/reserve", outReqAirline);

// Get the reservation status
var airlineResPayload =? inResAirline.getJsonPayload();
string airlineReservationStatus = airlineResPayload.Status.toString();
// If reservation status is negative, send a failure response to user
if (airlineReservationStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
                                          "Provide a valid 'Preference' for 'Airline' and try again"});
    _ = client -> respond(outResponse);
    return;
}
```

The above code shows how the travel agency service initiates a request to the airline reservation service to book a flight ticket. `airlineReservationEP` is the client endpoint you defined through which the Ballerina service communicates with the external airline reservation service.


Let's now look at the code segment that is responsible for communicating with the hotel reservation service. 

```ballerina
// Reserve hotel room for the user by calling Hotel reservation service
http:Request outReqHotel = {};
http:Response inResHotel = {};
// construct the payload
json outReqPayloadHotel = outReqPayload;
outReqPayloadHotel.Preference = hotelPreference;
outReqHotel.setJsonPayload(outReqPayloadHotel);

// Send a post request to hotelReservationService with appropriate payload and get response
inResHotel =? hotelReservationEP -> post("/reserve", outReqHotel);

// Get the reservation status
var hotelResPayload =? inResHotel.getJsonPayload();
string hotelReservationStatus = hotelResPayload.Status.toString();
// If reservation status is negative, send a failure response to user
if (hotelReservationStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
                                          "Provide a valid 'Preference' for 'Accommodation' and try again"});
    _ = client -> respond(outResponse);
    return;
}
```
The travel agency service communicates with the hotel reservation service to book a room for the client as shown above. The client endpoint defined for this external service call is `hotelReservationEP`.

Finally, let's look at the code segment that is responsible for communicating with the car rental service. 

```ballerina
// Renting car for the user by calling Car rental service
http:Request outReqCar = {};
http:Response inResCar = {};
// construct the payload
json outReqPayloadCar = outReqPayload;
outReqPayloadCar.Preference = carPreference;
outReqCar.setJsonPayload(outReqPayloadCar);

// Send a post request to carRentalService with appropriate payload and get response
inResCar =? carRentalEP -> post("/rent", outReqCar);

// Get the rental status
var carResPayload =? inResCar.getJsonPayload();
string carRentalStatus = carResPayload.Status.toString();
// If rental status is negative, send a failure response to user
if (carRentalStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to rent car! " +
                                          "Provide a valid 'Preference' for 'Car' and try again"});
    _ = client -> respond(outResponse);
    return;
}
```

As shown above, the travel agency service rents a car for the requested user by calling the car rental service. `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

## <a name="testing"></a> Testing 

### <a name="try-it"></a> Try it out

1. Start all four HTTP services by entering the following commands in separate terminals. This will start the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services in ports 9091, 9092, 9093 and 9090 respectively.

   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run AirlineReservation/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run HotelReservation/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run CarRental/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run TravelAgency/
   ```
   
2. Invoke the `travelAgencyService` by sending a POST request to arrange a tour.

   ```bash
    curl -v -X POST -d \
    '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
     "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
     "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
    ```

    The `travelAgencyService` sends a response similar to the following:
    
    ```bash
     < HTTP/1.1 200 OK
    {"Message":"Congratulations! Your journey is ready!!"}
    ``` 
   
   
### <a name="unit-testing"></a> Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'.  When writing the test functions the below convention should be followed.
* Test functions should be annotated with `@test:Config`. See the below example.
  ```ballerina
    @test:Config
    function testTravelAgencyService () {
  ```
  
This guide contains unit test cases for each service implemented above. 

To run the unit tests, go to the sample src directory and run the following command
   ```bash
   <SAMPLE_ROOT_DIRECTORY>/src$ ballerina test
   ```

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/AirlineReservation/test/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/HotelReservation/test/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/CarRental/test/car_rental_service_test.bal) and [travel_agency_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/TravelAgency/test/travel_agency_service_test.bal).


## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows.

Building 
   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina build <Package_Name>
   ```

Running
   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run target/<Exec_Archive_File_Name>
   ```

### <a name="deploying-on-docker"></a> Deploying on Docker
(Work in progress) 

### <a name="deploying-on-k8s"></a> Deploying on Kubernetes
(Work in progress) 


## <a name="observability"></a> Observability 

### <a name="logging"></a> Logging
(Work in progress) 

### <a name="metrics"></a> Metrics
(Work in progress) 


### <a name="tracing"></a> Tracing 
(Work in progress) 
