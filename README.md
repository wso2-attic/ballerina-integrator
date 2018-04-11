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

In the above image, 

(1), (2) - Check all the resources in parallel and wait for all three responses

(3)      - Checks all three resources in parallel and get only the first response

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

You can run the services that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 
Let's see how we can deploy the travel_agency_service_parallel we developed above on docker. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- In our travel_agency_service_parallel, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### travel_agency_service_parallel.bal
```ballerina
package TravelAgency;

import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"travel_agency_service",
    tag:"v1.0"
}

endpoint http:ServiceEndpoint travelAgencyEP {
    port:9090
};

@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {
   
``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command.  
  
  ```
  $ballerina build TravelAgency
  
  Run following command to start docker container: 
  docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
  ```
- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

    ```   
    docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
    ```
    Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl commands that we've used above. 
 
    ```
    curl -v -X POST -d \
    '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
    "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
    ```


### <a name="deploying-on-k8s"></a> Deploying on Kubernetes

- You can run the services that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, 
with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. 
So you don't need to explicitly create docker images prior to deploying it on Kubernetes.   
Let's see how we can deploy the travel_agency_service_parallel we developed above on kubernetes. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- We need to import `` import ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### travel_agency_service_parallel.bal

```ballerina
package TravelAgency;

import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
  hostname:"ballerina.guides.io",
  name:"ballerina-guides-travel-agency-service",
  path:"/"
}

@kubernetes:Service {
  serviceType:"NodePort",
  name:"ballerina-guides-travel-agency-service"
}

@kubernetes:Deployment {
  image:"ballerina.guides.io/travel_agency_service:v1.0",
  name:"ballerina-guides-travel-agency-service"
}

endpoint http:ServiceEndpoint travelAgencyEP {
    port:9090
};

// Http client endpoint definitions

@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {
        
``` 
- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service {} `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
  ```
  $ballerina build TravelAgency
  
  Run following command to deploy kubernetes artifacts:  
  kubectl apply -f ./target/TravelAgency/kubernetes
 
  ```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker ps images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/TravelAgency/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
 $ kubectl apply -f ./target/TravelAgency/kubernetes 
   deployment.extensions "ballerina-guides-travel-agency-service" created
   ingress.extensions "ballerina-guides-travel-agency-service" created
   service "ballerina-guides-travel-agency-service" created

```
- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 
```
$kubectl get service
$kubectl get deploy
$kubectl get pods
$kubectl get ingress

```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
  curl -v -X POST -d \
  '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
  "http://<Minikube_host_IP>:<Node_Port>/travel/arrangeTour" -H "Content-Type:application/json"  

```
Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service 

``` 
 curl -v -X POST -d \
'{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
 "http://ballerina.guides.io/travel/arrangeTour" -H "Content-Type:application/json" 
    
```


## <a name="observability"></a> Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file in `parallel-service-orchestration/src/`.

```ballerina
[observability]

[observability.metrics]
# Flag to enable Metrics
enabled=true

[observability.tracing]
# Flag to enable Tracing
enabled=true

```

### <a name="tracing"></a> Tracing 
You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.
1) Run Jaeger docker image using the following command
   ```bash
   docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 -p14268:14268 jaegertracing/all- in-one:latest
   ```
2) Navigate to `parallel-service-orchestration/src/` and start all services using following command 
   ```
   $ballerina run <package_name>
   ```
   
3) Observe the tracing using Jaeger UI using following URL
   ```
   http://localhost:16686
   ```
4) You should see the Jaeger UI as follows

   ![Jaeger UI](images/tracing-screenshot.png "Tracing Screenshot")
 

### <a name="metrics"></a> Metrics
Metrics and alarts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for Ballerina restful service.

1) Set the below configurations in the `ballerina.conf` file in the project root.
   ```ballerina
   [observability.metrics.prometheus]
   # Flag to enable Prometheus HTTP endpoint
   enabled=true
   # Prometheus HTTP endpoint port. Metrics will be exposed in /metrics context.
   # Eg: http://localhost:9797/metrics
   port=9797
   # Flag to indicate whether meter descriptions should be sent to Prometheus.
   descriptions=false
   # The step size to use in computing windowed statistics like max. The default is 1 minute.
   step="PT1M"

   ```
2) Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
   ```
   global:
   scrape_interval:     15s
   evaluation_interval: 15s

   scrape_configs:
    - job_name: 'prometheus'
   
   static_configs:
        - targets: ['172.17.0.1:9797']
   ```
   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
3) Run the Prometheus docker image using the following command
   ```
   docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/tmp/prometheus.yml prom/prometheus
   ```

4) Navigate to `parallel-service-orchestration/src/` and start all services using following command 
   ```
   $ballerina run <package_name>
   ```
   NOTE: First start the `TravelAgency` package since it's the main orchastrator for other services(also we are going to trace from Traval Agancy service)
   
5) You can access Prometheus at the following URL
   ```
   http://localhost:19090/
   ```
   NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
   
  		-  http_requests_total
		-  http_response_time

6) Promethues UI screenshot
   
   ![promethues screenshot](images/metrics-screenshot.png "Prometheus UI")

### <a name="logging"></a> Logging
Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

1) Start the Ballerina Service with the following command from `{SAMPLE_ROOT_DIRECTORY}/src`
   ```
   nohup ballerina run TravelAgency/ &>> ballerina.log&
   ```
   NOTE: This will write the console log to the `ballerina.log` file in the `{SAMPLE_ROOT_DIRECTORY}/src` directory
2) Start Elasticsearch using the following command

   ```
   docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name  
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
   ```
   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
3) Start Kibana plugin for data visualization with Elasticsearch
   ```
   docker run -p 5601:5601 -h kibana --name kibana --link elasticsearch:elasticsearch 
   docker.elastic.co/kibana/kibana:6.2.2     
   ```
4) Configure logstash to format the ballerina logs
   
   i) Create a file named `logstash.conf` with the following content
      ```
      input {  
       beats { 
	       port => 5044 
	      }  
      }
      
      filter {  
       grok  {  
	       match => { 
                  "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
                  \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
                 }  
       }  
      }   
      
      output {  
       elasticsearch {  
    	   hosts => "elasticsearch:9200"  
    	   index => "store"  
           document_type => "store_logs"  
	      }  
      }  
      ```
      NOTE: We have declared `store` as the index using `index => "store"` statement.
      
     ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT_DIRECTORY}\pipeline`
     
     iii) Start the logstash container, replace the {SAMPLE_ROOT_DIRECTORY} with your directory name
     
     ```
        docker run -h logstash --name logstash --link elasticsearch:elasticsearch -it --rm 
        -v {SAMPLE_ROOT_DIRECTIRY}/pipeline:/usr/share/logstash/pipeline/ 
        -p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
     ```
  
 5) Configure filebeat to ship the ballerina logs
    
     i) Create a file named `filebeat.yml` with the following content
      ```
       filebeat.prospectors:
          - type: log
       paths:
          - /usr/share/filebeat/ballerina.log
       output.logstash:
            hosts: ["logstash:5044"]
      ```
     ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT_DIRECTORY}\filebeat`   
        
     
     iii) Start the logstash container, replace the {SAMPLE_ROOT_DIRECTORY} with your directory name
     
     ```
        docker run -v {SAMPLE_ROOT_DIRECTORY}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml 
        -v {SAMPLE_ROOT_DIRECTORY}/src/restful_service/ballerina.log:/usr/share/filebeat/ballerina.log
	    --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
     ```
 
 6) Access Kibana to visualize the logs using following URL
    ```
     http://localhost:5601 
    ```
    NOTE: You may need to add `store` index pattern to kibana visualization tool to create a log visualization.
    
 7) Screenshot of Kibana log visualization
 
     ![logging screenshot](images/logging-screenshot.png "Kibana UI")
     
