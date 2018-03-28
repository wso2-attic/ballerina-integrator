# Parallel Service Orchestration

Parallel service orchestration is the process of integrating two or more services together to automate a particular task or business process where the service orchestrator consumes the resources available in services in a parallel manner. 

> This guide walks you through the process of implementing a parallel service orchestration using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the service](#developing-service)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
- [Observability](#observability)

## <a name="what-you-build"></a>  What you’ll build
To understand how you can build a parallel service orchestration using Ballerina, let's consider a real-world use case of a travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the travel agency service requires communicating with other necessary back-ends. 

This scenario is similar to the scenario used in the [service-composition guide](https://github.com/ballerina-guides/service-composition) except, all three external services (airline reservation, hotel reservation and car rental) contain multiple resources. The travel agency service checks these resources in parallel to select the best-suited resource for each requirement. For example, the travel agency service checks three different airways in parallel and selects the airway with the lowest cost. Similarly, it checks several hotels in parallel and selects the closest one to the client's preferred location. The following diagram illustrates this use case.

![alt text](/images/parallel_service_orchestration.png)

Travel agency is the service that acts as the service orchestration initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

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
parallel-service-orchestration
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
           │   └── travel_agency_service_parallel_test.bal
           └── travel_agency_service_parallel.bal

```

Package `AirlineReservation` contains the service that provides airline ticket reservation functionality.

Package `CarRental` contains the service that provides car rental functionality.

Package `HotelReservation` contains the service that provides hotel room reservation functionality.

The `travel_agency_service_parallel.bal` file consists of the travel agency service, which communicates with the other three services, and arranges a complete tour for the client.


### <a name="Implementation"></a> Implementation

Let's look at the implementation of the travel agency service, which acts as the service orchestration initiator.

To arrange a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. These external services consist of multiple resources, which can be consumed by the callers. The airline reservation service has three different resources each depicting an airline service provider. Similarly, the hotel reservation service has three resources to check different hotels and the car rental service has three resources to check different rental providing companies. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. 

Sample request payload for the airline reservation service:

```bash
{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi"} 
```

Sample response payload from the airline reservation service:

```bash
{"Airline":"Emirates", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018", "From":"Colombo", "To":"Changi", "Price":273}
```

Sample request payload for the hotel reservation service:

```bash
{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "Location":"Changi"}
```

Sample response payload from the hotel reservation service:

```bash
{"HotelName":"Miramar", "FromDate":"12-03-2018", "ToDate":"13-04-2018", "DistanceToLocation":6}
```

Sample request payload for the car rental service:

```bash
{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "VehicleType":"Car"}
```

Sample response payload from the car rental service:

```bash
{"Company":"DriveSG", "VehicleType":"Car", "FromDate":"12-03-2018", "ToDate":"13-04-2018", "PricePerDay":5}
```

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to arrange an airline. The airline reservation service allows the client to check about three different airlines by providing a separate resource for each airline. To check the implementation of airline reservation service, see the [airline_reservation_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/AirlineReservation/airline_reservation_service.bal) file.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. The hotel reservation service allows the client to check about three different hotels by providing a separate resource for each hotel. To check the implementation of hotel reservation service, see the [hotel_reservation_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/HotelReservation/hotel_reservation_service.bal) file.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. The car rental service also provides three different resources for three car rental providing companies. To check the implementation of car rental service, see the [car_rental_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/CarRental/car_rental_service.bal) file.

When communicating with an external service, the travel agency service sends separate requests for all the available resources in parallel.

The travel agency service checks if all three airlines available in parallel and waits for all of them to respond. Once it receives the responses, it selects the airline that has the lowest cost. Refer to the following code snippet, which is responsible for the integration with the airline reservation service.

```ballerina
// Airline reservation
// Call Airline reservation service and consume different resources in parallel to check different airways
// Fork - Join to run parallel workers and join the results
fork {
    // Worker to communicate with airline 'Qatar Airways'
    worker qatarWorker {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(flightPayload);
        // Send a POST request to 'Qatar Airways' and get the results
        http:Response respWorkerQatar =? airlineReservationEP -> post("/qatarAirways", outRequest);
        // Reply to the join block from this worker - Send the response from 'Qatar Airways'
        respWorkerQatar -> fork;
    }

    // Worker to communicate with airline 'Asiana'
    worker asianaWorker {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(flightPayload);
        // Send a POST request to 'Asiana' and get the results
        http:Response respWorkerAsiana =? airlineReservationEP -> post("/asiana", outRequest);
        // Reply to the join block from this worker - Send the response from 'Asiana'
        respWorkerAsiana -> fork;
    }

    // Worker to communicate with airline 'Emirates'
    worker emiratesWorker {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(flightPayload);
        // Send a POST request to 'Emirates' and get the results
        http:Response respWorkerEmirates =? airlineReservationEP -> post("/emirates", outRequest);
        // Reply to the join block from this worker - Send the response from 'Emirates'
        respWorkerEmirates -> fork;
    }
} join (all) (map airlineResponses) {
    // Wait until the responses received from all the workers running in parallel
    int qatarPrice;
    int asianaPrice;
    int emiratesPrice;

    // Get the response and price for airline 'Qatar Airways'
    if (airlineResponses["qatarWorker"] != null) {
        var resQatarWorker =? <any[]>airlineResponses["qatarWorker"];
        var responseQatar =? <http:Response>(resQatarWorker[0]);
        jsonFlightResponseQatar =? responseQatar.getJsonPayload();
        qatarPrice =? <int>jsonFlightResponseQatar.Price.toString();
    }

    // Get the response and price for airline 'Asiana'
    if (airlineResponses["asianaWorker"] != null) {
        var resAsianaWorker =? <any[]>airlineResponses["asianaWorker"];
        var responseAsiana =? <http:Response>(resAsianaWorker[0]);
        jsonFlightResponseAsiana =? responseAsiana.getJsonPayload();
        asianaPrice =? <int>jsonFlightResponseAsiana.Price.toString();
    }

    // Get the response and price for airline 'Emirates'
    if (airlineResponses["emiratesWorker"] != null) {
        var resEmiratesWorker =? <any[]>airlineResponses["emiratesWorker"];
        var responseEmirates =? (<http:Response>(resEmiratesWorker[0]));
        jsonFlightResponseEmirates =? responseEmirates.getJsonPayload();
        emiratesPrice =? <int>jsonFlightResponseEmirates.Price.toString();
    }

    // Select the airline with the least price
    if (qatarPrice < asianaPrice) {
        if (qatarPrice < emiratesPrice) {
            jsonFlightResponse = jsonFlightResponseQatar;
        }
    } else {
        if (qatarPrice < emiratesPrice) {
            jsonFlightResponse = jsonFlightResponseAsiana;
        }
        else {
            jsonFlightResponse = jsonFlightResponseEmirates;
        }
    }
}

```

As shown in the above code, we used `fork-join` to run parallel workers and join their responses. The fork-join allows developers to spawn (fork) multiple workers within a Ballerina program and join the results from those workers. Here we used "all" as the join condition, which means the program waits for all the workers to respond.

Let's now look at how the travel agency service integrates with the hotel reservation service. Similar to the above scenario, the travel agency service sends requests to all three available resources in parallel and waits for all of them to respond. Once it receives the responses, it selects the hotel that is closest to the client's preferred location. Refer to the following code snippet.

```ballerina
// Hotel reservation
// Call Hotel reservation service and consume different resources in parallel to check different hotels
// Fork - Join to run parallel workers and join the results
fork {
    // Worker to communicate with hotel 'Miramar'
    worker miramar {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(hotelPayload);
        // Send a POST request to 'Asiana' and get the results
        http:Response respWorkerMiramar =? hotelReservationEP -> post("/miramar", outRequest);
        // Reply to the join block from this worker - Send the response from 'Asiana'
        respWorkerMiramar -> fork;
    }

    // Worker to communicate with hotel 'Aqueen'
    worker aqueen {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(hotelPayload);
        // Send a POST request to 'Aqueen' and get the results
        http:Response respWorkerAqueen =? hotelReservationEP -> post("/aqueen", outRequest);
        // Reply to the join block from this worker - Send the response from 'Aqueen'
        respWorkerAqueen -> fork;
    }

    // Worker to communicate with hotel 'Elizabeth'
    worker elizabeth {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(hotelPayload);
        // Send a POST request to 'Elizabeth' and get the results
        http:Response respWorkerElizabeth =? hotelReservationEP -> post("/elizabeth", outRequest);
        // Reply to the join block from this worker - Send the response from 'Elizabeth'
        respWorkerElizabeth -> fork;
    }
} join (all) (map hotelResponses) {
    // Wait until the responses received from all the workers running in parallel

    int miramarDistance;
    int aqueenDistance;
    int elizabethDistance;

    // Get the response and distance to the preferred location from the hotel 'Miramar'
    if (hotelResponses["miramar"] != null) {
        var resMiramarWorker =? <any[]>hotelResponses["miramar"];
        var responseMiramar =? <http:Response>(resMiramarWorker[0]);
        miramarJsonResponse =? responseMiramar.getJsonPayload();
        miramarDistance =? <int>miramarJsonResponse.DistanceToLocation.toString();
    }

    // Get the response and distance to the preferred location from the hotel 'Aqueen'
    if (hotelResponses["aqueen"] != null) {
        var resAqueenWorker =? <any[]>hotelResponses["aqueen"];
        var responseAqueen =? <http:Response>(resAqueenWorker[0]);
        aqueenJsonResponse =? responseAqueen.getJsonPayload();
        aqueenDistance =? <int>aqueenJsonResponse.DistanceToLocation.toString();
    }

    // Get the response and distance to the preferred location from the hotel 'Elizabeth'
    if (hotelResponses["elizabeth"] != null) {
        var resElizabethWorker =? <any[]>hotelResponses["elizabeth"];
        var responseElizabeth =? (<http:Response>(resElizabethWorker[0]));
        elizabethJsonResponse =? responseElizabeth.getJsonPayload();
        elizabethDistance =? <int>elizabethJsonResponse.DistanceToLocation.toString();
    }

    // Select the hotel with the lowest distance
    if (miramarDistance < aqueenDistance) {
        if (miramarDistance < elizabethDistance) {
            jsonHotelResponse = miramarJsonResponse;
        }
    } else {
        if (aqueenDistance < elizabethDistance) {
            jsonHotelResponse = aqueenJsonResponse;
        }
        else {
            jsonHotelResponse = elizabethJsonResponse;
        }
    }
}

```

Let's next look at how the travel agency service integrates with the car rental service. The travel agency service sends requests to all three car rental providers in parallel and gets only the first one to respond. Refer to the following code snippet.

```ballerina
// Car rental
// Call Car rental service and consume different resources in parallel to check different companies
// Fork - Join to run parallel workers and join the results
fork {
    // Worker to communicate with Company 'DriveSg'
    worker driveSg {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(vehiclePayload);
        // Send a POST request to 'DriveSg' and get the results
        http:Response respWorkerDriveSg =? carRentalEP -> post("/driveSg", outRequest);
        // Reply to the join block from this worker - Send the response from 'DriveSg'
        respWorkerDriveSg -> fork;
    }

    // Worker to communicate with Company 'DreamCar'
    worker dreamCar {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(vehiclePayload);
        // Send a POST request to 'DreamCar' and get the results
        http:Response respWorkerDreamCar =? carRentalEP -> post("/dreamCar", outRequest);
        // Reply to the join block from this worker - Send the response from 'DreamCar'
        respWorkerDreamCar -> fork;
    }

    // Worker to communicate with Company 'Sixt'
    worker sixt {
        http:Request outRequest = {};
        // Out request payload
        outRequest.setJsonPayload(vehiclePayload);
        // Send a POST request to 'Sixt' and get the results
        http:Response respWorkerSixt =? carRentalEP -> post("/sixt", outRequest);
        // Reply to the join block from this worker - Send the response from 'Sixt'
        respWorkerSixt -> fork;
    }
} join (some 1) (map vehicleResponses) {
    // Get the first responding worker

    // Get the response from company 'DriveSg' if not null
    if (vehicleResponses["driveSg"] != null) {
        var resDriveSgWorker =? <any[]>vehicleResponses["driveSg"];
        var responseDriveSg =? <http:Response>(resDriveSgWorker[0]);
        jsonVehicleResponse =? responseDriveSg.getJsonPayload();
    } else if (vehicleResponses["dreamCar"] != null) {
        // Get the response from company 'DreamCar' if not null
        var resDreamCarWorker =? <any[]>vehicleResponses["dreamCar"];
        var responseDreamCar =? <http:Response>(resDreamCarWorker[0]);
        jsonVehicleResponse =? responseDreamCar.getJsonPayload();
    } else if (vehicleResponses["sixt"] != null) {
        // Get the response from company 'Sixt' if not null
        var resSixtWorker =? <any[]>vehicleResponses["sixt"];
        var responseSixt =? (<http:Response>(resSixtWorker[0]));
        jsonVehicleResponse =? responseSixt.getJsonPayload();
    }
}

```

Here we used "some 1" as the join condition, which means the program gets results from only one worker, which responds first. Therefore, the travel agency service gets the car rental provider that responds first.

Finally, let's look at the structure of the `travel_agency_service_parallel.bal` file that is responsible for the Travel agency service.

##### travel_agency_service_parallel.bal

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
      
        // Try parsing the JSON payload from the user request

        // Integration with Airline reservation service to reserve an airline

        // Integration with the hotel reservation service to reserve a hotel

        // Integration with the car rental service to rent a vehicle
        
        // Respond back to the client
    }
}

```

In the above code, `airlineReservationEP` is the client endpoint defined through which the Ballerina service communicates with the external airline reservation service. The client endpoint defined to communicate with the external hotel reservation service is `hotelReservationEP`. Similarly, `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

To see the complete implementation of the above file, refer to the [travel_agency_service_parallel.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/TravelAgency/travel_agency_service_parallel.bal) file.


## <a name="testing"></a> Testing 

### <a name="try-it"></a> Try it out

1. Start all four HTTP services by entering the following command in a separate terminal for each service. This command starts the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services in ports 9091, 9092, 9093, and 9090 respectively.  Here `<Package_Name>` is the corresponding package name in which each service file is located.

   ```bash
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run <Package_Name>
   ```
   
2. Invoke the `travelAgencyService` by sending a POST request to arrange a tour.

   ```bash
    curl -v -X POST -d \
    '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
    "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
   ```

   The `travelAgencyService` sends a response similar to the following:
    
   ```bash
    < HTTP/1.1 200 OK
    {
      "Flight":{"Airline":"Emirates","ArrivalDate":"12-03-2018","ReturnDate":"13-04-2018","From":"Colombo","To":"Changi","Price":273},
      "Hotel":{"HotelName":"Elizabeth","FromDate":"12-03-2018","ToDate":"13-04-2018","DistanceToLocation":2},
      "Vehicle":{"Company":"DriveSG","VehicleType":"Car","FromDate":"12-03-2018","ToDate":"13-04-2018","PricePerDay":5}
    }
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

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/AirlineReservation/test/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/HotelReservation/test/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/CarRental/test/car_rental_service_test.bal), and [travel_agency_service_parallel_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/src/TravelAgency/test/travel_agency_service_parallel_test.bal).


## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows.

**Building** 
   ```bash
    <SAMPLE_ROOT_DIRECTORY/src>$ ballerina build <Package_Name>
   ```

**Running**
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
