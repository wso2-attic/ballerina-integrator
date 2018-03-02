# Service Composition

This guide walks you through the process of implementing a service composition using Ballerina language. A service composition is an aggregate of services collectively composed to automate a particular task or business process. 

## <a name="what-you-build"></a>  What you’ll Build
To understanding how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency, which arranges complete tour packages for users. Tour package includes Airline ticket reservation, Hotel room reservation and Car rental. Therefore, the Travel agency required to communicate with other back-ends, which provide the above-mentioned services. Once a client initiates a request to arrange a tour, the Travel agency service will first communicate with the Airline reservation service to book the flight ticket. Then it will communicate with the Hotel reservation service to reserve hotel rooms. Finally, it will connect with the Car rental service to arrange internal transports. If all successful, the Travel agency service will confirm and arrange the complete tour for the user. The below diagram illustrates this use case clearly.


![alt text](https://github.com/pranavan15/service-composition/blob/master/images/serviceComposition.png)



## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- Ballerina Distribution (Install Instructions:  https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- A Text Editor or an IDE 

Optional Requirements
- Docker (Follow instructions in https://docs.docker.com/engine/installation/)
- Ballerina IDE plugins. ( IntelliJ IDEA, VSCode, Atom)
- Testerina (Refer: https://github.com/ballerinalang/testerina)
- Container-support (Refer: https://github.com/ballerinalang/container-support)
- Docerina (Refer: https://github.com/ballerinalang/docerina)

## <a name="developing-service"></a> Developing the Service

### <a name="before-begin"></a> Before You Begin
##### Understand the Package Structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
service-composition
├── TravelAgency
│   ├── AirlineReservation
│   │   ├── airline_reservation_service.bal
│   │   └── airline_reservation_service_test.bal
│   ├── CarRental
│   │   ├── car_rental_service.bal
│   │   └── car_rental_service_test.bal
│   ├── HotelReservation
│   │   ├── hotel_reservation_service.bal
│   │   └── hotel_reservation_service_test.bal
│   ├── travel_agency_service.bal
│   └── travel_agency_service_test.bal
└── README.md

```

Package `AirlineReservation` contains the service that provides online flight ticket reservations.

Package `CarRental` contains the service that provides online car rentals.

Package `HotelReservation` contains the service that provides online hotel room reservations.

`travel_agency_service.bal` file provides travel agency service, which consumes the other three services and arranges a complete tour for the requested user.


### <a name="Implementation"></a> Implementation

Let's get started with the implementation of `travel_agency_service.bal` file, which includes the implementation of the Travel agency service. This is the service that acts as the composition initiator. It gets requests from users for tour arrangements and communicates with other necessary services to successfully arrange a complete journey for the user. Refer the code attached below. Inline comments are added for better understanding.


##### travel_agency_service.bal

```ballerina
package TravelAgency;

import ballerina.net.http;
import ballerina.log;

// Travel agency service to arrange a complete tour for a user
@http:configuration {basePath:"/travel", port:9090}
service<http> travelAgencyService {

    // Endpoint to communicate with Airline reservation service
    endpoint<http:HttpClient> airlineReservationEP {
        create http:HttpClient("http://localhost:9091/airline", {});
    }

    // Endpoint to communicate with Hotel reservation service
    endpoint<http:HttpClient> hotelReservationEP {
        create http:HttpClient("http://localhost:9092/hotel", {});
    }

    // Endpoint to communicate with Car rental service
    endpoint<http:HttpClient> carRentalEP {
        create http:HttpClient("http://localhost:9093/car", {});
    }

    // Resource to arrange a tour
    @http:resourceConfig {methods:["POST"]}
    resource arrangeTour (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};
        string name;
        json hotelPreference;
        json airlinePreference;
        json carPreference;
        // Json payload format for an http out request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"", "Preference":""};

        // Try parsing the JSON payload from the user request
        try {
            log:printInfo("Parsing request payload");
            json inReqPayload = inRequest.getJsonPayload();
            name = inReqPayload.Name.toString();
            outReqPayload.Name = name;
            outReqPayload.ArrivalDate = inReqPayload.ArrivalDate.toString();
            outReqPayload.DepartureDate = inReqPayload.DepartureDate.toString();
            airlinePreference = inReqPayload.Preference.Airline.toString();
            hotelPreference = inReqPayload.Preference.Accommodation.toString();
            carPreference = inReqPayload.Preference.Car.toString();
            log:printInfo("Successfully parsed; Username: " + name);
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
            log:printWarn("Failed to parse! Bad user request\n");
            return;
        }


        // Reserve airline ticket for the user by calling Airline reservation service
        log:printInfo("Reserving airline ticket for user: " + name);
        http:OutRequest outReqAirline = {};
        http:InResponse inResAirline = {};
        // construct the payload
        json outReqPayloadAirline = outReqPayload;
        outReqPayloadAirline.Preference = airlinePreference;
        outReqAirline.setJsonPayload(outReqPayloadAirline);

        // Send a post request to airlineReservationService with appropriate payload and get response
        inResAirline, _ = airlineReservationEP.post("/reserve", outReqAirline);

        // Get the reservation status
        string airlineReservationStatus = inResAirline.getJsonPayload().Status.toString();
        // If reservation status is negative, send a failure response to user
        if (airlineReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve airline! " + 
            "Provide a valid 'Preference' for 'Airline' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to reserve ticket\n");
            return;
        }
        log:printInfo("Airline reservation successful!");


        // Reserve hotel room for the user by calling Hotel reservation service
        log:printInfo("Reserving hotel room for user: " + name);
        http:OutRequest outReqHotel = {};
        http:InResponse inResHotel = {};
        // construct the payload
        json outReqPayloadHotel = outReqPayload;
        outReqPayloadHotel.Preference = hotelPreference;
        outReqHotel.setJsonPayload(outReqPayloadHotel);

        // Send a post request to hotelReservationService with appropriate payload and get response
        inResHotel, _ = hotelReservationEP.post("/reserve", outReqHotel);

        // Get the reservation status
        string hotelReservationStatus = inResHotel.getJsonPayload().Status.toString();
        // If reservation status is negative, send a failure response to user
        if (hotelReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " + 
            "Provide a valid 'Preference' for 'Accommodation' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to reserve room\n");
            return;
        }
        log:printInfo("Hotel reservation successful!");


        // Renting car for the user by calling Car rental service
        log:printInfo("Renting car for user: " + name);
        http:OutRequest outReqCar = {};
        http:InResponse inResCar = {};
        // construct the payload
        json outReqPayloadCar = outReqPayload;
        outReqPayloadCar.Preference = carPreference;
        outReqCar.setJsonPayload(outReqPayloadCar);

        // Send a post request to carRentalService with appropriate payload and get response
        inResCar, _ = carRentalEP.post("/rent", outReqCar);

        // Get the rental status
        string carRentalStatus = inResCar.getJsonPayload().Status.toString();
        // If rental status is negative, send a failure response to user
        if (carRentalStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to rent car! " +
            "Provide a valid 'Preference' for 'Car' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to rent car\n");
            return;
        }
        log:printInfo("Car rental successful!");


        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        _ = connection.respond(outResponse);
        log:printInfo("Successfully arranged tour for user: " + name + " !!\n");
    }
}

```

## <a name="testing"></a> Testing 

### <a name="try-it"></a> Try it Out

1. Start all 4 http services by entering the following commands in sperate terminals. This will start the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services in ports 9091, 9092, 9093 and 9090 respectively.

   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run TravelAgency/AirlineReservation/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run TravelAgency/HotelReservation/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run TravelAgency/CarRental/
   ```
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run TravelAgency/
   ```
   
2. Invoke the `travelAgencyService` by sending a POST request to arrange a tour,

   ```bash
    curl -v -X POST -d \
    '{"Name":"Alice", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
      "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
     "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
    ```

    The `travelAgencyService` should respond something similar,
    
    ```bash
     < HTTP/1.1 200 OK
    {"Message":"Congratulations! Your journey is ready!!"}
    ``` 

   Sample Log Messages
   
   ```
    2018-02-28 10:34:14,198 INFO  [TravelAgency] - Parsing request payload 
    2018-02-28 10:34:14,201 INFO  [TravelAgency] - Successfully parsed; Username: Alice 
    2018-02-28 10:34:14,203 INFO  [TravelAgency] - Reserving airline ticket for user: Alice
    
    2018-02-28 10:34:14,212 INFO  [TravelAgency.AirlineReservation] - Successfully reserved airline ticket for user: Alice 
    
    2018-02-28 10:34:14,217 INFO  [TravelAgency] - Airline reservation successful! 
    2018-02-28 10:34:14,217 INFO  [TravelAgency] - Reserving hotel room for user: Alice
    
    2018-02-28 10:34:14,221 INFO  [TravelAgency.HotelReservation] - Successfully reserved hotel room for user: Alice 
    
    2018-02-28 10:34:14,225 INFO  [TravelAgency] - Hotel reservation successful! 
    2018-02-28 10:34:14,225 INFO  [TravelAgency] - Renting car for user: Alice
    
    2018-02-28 10:34:14,229 INFO  [TravelAgency.CarRental] - Successfully rented car for user: Alice 
    
    2018-02-28 10:34:14,233 INFO  [TravelAgency] - Car rental successful! 
    2018-02-28 10:34:14,235 INFO  [TravelAgency] - Successfully arranged tour for user: Alice !!    
   ```
   
   
### <a name="unit-testing"></a> Writing Unit Tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g.: testTravelAgencyService()

This guide contains unit test cases for each service implemented above. 

Test files are in the same packages in which the service files are located.

To run the unit tests, go to the sample root directory and run the following command
   ```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina test TravelAgency/
   ```

To check the implementations of these test files, please go to https://github.com/ballerina-guides/service-composition/blob/master/TravelAgency/ and refer the respective folders of `airline_reservation_service.bal`,
`car_rental_service.bal`, `hotel_reservation_service.bal` and `travel_agency_service.bal` files. 

## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the services using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying Locally
You can deploy the RESTful services that you developed above, in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows,

Building 
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina build TravelAgency/AirlineReservation/

    <SAMPLE_ROOT_DIRECTORY>$ ballerina build TravelAgency/HotelReservation/

    <SAMPLE_ROOT_DIRECTORY>$ ballerina build TravelAgency/CarRental/
    
    <SAMPLE_ROOT_DIRECTORY>$ ballerina build TravelAgency/

   ```

Running
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run AirlineReservation.balx
    
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run HotelReservation.balx 

    <SAMPLE_ROOT_DIRECTORY>$ ballerina run CarRental.balx
     
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run TravelAgency.balx

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
