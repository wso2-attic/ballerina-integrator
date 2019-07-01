# Parallel Service Orchestration

Parallel service orchestration is the process of integrating two or more services together to automate a particular task or business process where the service orchestrator consumes the resources available in services in a parallel manner. 

> This guide walks you through the process of implementing a parallel service orchestration using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understand how you can build a parallel service orchestration using Ballerina, let's consider a real-world use case of a travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the travel agency service requires communicating with other necessary back-ends. 

This scenario is similar to the scenario used in the [service-composition guide](https://ballerina.io/learn/guides/service-composition) except, all three external services (airline reservation, hotel reservation and car rental) contain multiple resources. The travel agency service checks these resources in parallel to select the best-suited resource for each requirement. For example, the travel agency service checks three different airways in parallel and selects the airway with the lowest cost. Similarly, it checks several hotels in parallel and selects the closest one to the client's preferred location. The following diagram illustrates this use case.

![alt text](/resources/parallel-service-orchestration.svg)

In the above image, 

(1), (2) - Check all the resources in parallel and wait for all three responses

(3)      - Checks all three resources in parallel and get only the first response

Travel agency is the service that acts as the service orchestration initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

### Optional requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping  "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following module structure
 for this guide.

```
parallel-service-orchestration
   └── guide
       ├── airline_reservation
       │   ├── airline_reservation_service.bal
       │   └── tests
       │       └── airline_reservation_service_test.bal
       ├── car_rental
       │   ├── car_rental_service.bal
       │   └── tests
       │       └── car_rental_service_test.bal
       ├── hotel_reservation
       │   ├── hotel_reservation_service.bal
       │   └── tests
       │       └── hotel_reservation_service_test.bal
       ├── travel_agency
       │   └── travel_agency_service_parallel.bal
       └── tests
           └── travel_agency_service_parallel_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `parallel-service-orchestration/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the service

Let's look at the implementation of the travel agency service, which acts as the service orchestration initiator.

To arrange a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. These external services consist of multiple resources, which can be consumed by the callers. The airline reservation service has three different resources each depicting an airline service provider. Similarly, the hotel reservation service has three resources to check different hotels and the car rental service has three resources to check different rental providing companies. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. 

Sample request payload for the airline reservation service:

```bash
{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", "To":"Changi"} 
```

Sample response payload from the airline reservation service:

```bash
{"Airline":"Emirates", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018", 
 "From":"Colombo", "To":"Changi", "Price":273}
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
{"Company":"DriveSG", "VehicleType":"Car", "FromDate":"12-03-2018", "ToDate":"13-04-2018",
 "PricePerDay":5}
```

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to arrange an airline. The airline reservation service allows the client to check about three different airlines by providing a separate resource for each airline. To check the implementation of airline reservation service, see the [airline_reservation_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/airline_reservation/airline_reservation_service.bal) file.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. The hotel reservation service allows the client to check about three different hotels by providing a separate resource for each hotel. To check the implementation of hotel reservation service, see the [hotel_reservation_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/hotel_reservation/hotel_reservation_service.bal) file.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. The car rental service also provides three different resources for three car rental providing companies. To check the implementation of car rental service, see the [car_rental_service.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/car_rental/car_rental_service.bal) file.

When communicating with an external service, the travel agency service sends separate requests for all the available resources in parallel.

The travel agency service checks if all three airlines available in parallel and waits for all of them to respond. Once it receives the responses, it selects the airline that has the lowest cost. Refer to the following code snippet, which is responsible for the integration with the airline reservation service.

```ballerina
// Airline reservation
// Call Airline reservation service and consume different resources in parallel to check different airways
// fork to run parallel workers and join the results
fork {
    // Worker to communicate with airline 'Qatar Airways'
    worker qatarWorker returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint flightPayload);
        // Send a POST request to 'Qatar Airways' and get the results
        var respWorkerQuatar = airlineEP->post("/qatarAirways", outReq);
        // Reply to the join block from this worker - Send the response from 'Qatar Airways'
        if (respWorkerQuatar is http:Response) {
            return respWorkerQuatar;
        }
        return;
    }

    // Worker to communicate with airline 'Asiana'
    worker asianaWorker returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint flightPayload);
        // Send a POST request to 'Asiana' and get the results
        var respWorkerAsiana = airlineEP->post("/asiana", outReq);
        // Reply to the join block from this worker - Send the response from 'Asiana'
        if (respWorkerAsiana is http:Response) {
            return respWorkerAsiana;
        }
        return;
    }

    // Worker to communicate with airline 'Emirates'
    worker emiratesWorker returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint flightPayload);
        // Send a POST request to 'Emirates' and get the results
        var respWorkerEmirates = airlineEP->post("/emirates", outReq);
        // Reply to the join block from this worker - Send the response from 'Emirates'
        if (respWorkerEmirates is http:Response) {
            return respWorkerEmirates;
        }
        return;
    }
}

// Wait until the responses received from all the workers running in parallel
record{
    http:Response? qatarWorker;
    http:Response? asianaWorker;
    http:Response? emiratesWorker;
} airlineResponses = wait {qatarWorker, asianaWorker, emiratesWorker};

int qatarPrice = -1;
int asianaPrice = -1;
int emiratesPrice = -1;

// Get the response and price for airline 'Qatar Airways'
var resQatar = airlineResponses["qatarWorker"];
if (resQatar is http:Response) {
    var flightResponseQutar= resQatar.getJsonPayload();
    if (flightResponseQutar is json) {
        jsonFlightResponseQatar = flightResponseQutar;
        var qatarResult = jsonFlightResponseQatar.Price;
        if (qatarResult is int) {
            qatarPrice = qatarResult;
        }
    }
}

// Get the response and price for airline 'Asiana'
var resAsiana = airlineResponses["asianaWorker"];
if (resAsiana is http:Response) {
    var flightResponseAsia = resAsiana.getJsonPayload();
    if (flightResponseAsia is json) {
        jsonFlightResponseAsiana = flightResponseAsia;
        var asianaResult = jsonFlightResponseAsiana.Price;
        if (asianaResult is int) {
            asianaPrice = asianaResult;
        }
    }
}

// Get the response and price for airline 'Emirates'
var resEmirates = airlineResponses["emiratesWorker"];
if (resEmirates is http:Response) {
    var flightResponseEmirates = resEmirates.getJsonPayload();
    if (flightResponseEmirates is json) {
        jsonFlightResponseEmirates = flightResponseEmirates;
        var emiratesResult = jsonFlightResponseEmirates.Price;
        if (emiratesResult is int) {
            emiratesPrice = emiratesResult;
        }
    }
}

// Select the airline with the least price
if (qatarPrice < asianaPrice) {
    if (qatarPrice < emiratesPrice) {
        jsonFlightResponse = jsonFlightResponseQatar;
    }
} else {
    if (asianaPrice < emiratesPrice) {
        jsonFlightResponse = jsonFlightResponseAsiana;
    } else {
        jsonFlightResponse = jsonFlightResponseEmirates;
    }
}
```

As shown in the above code, we used `fork` to run parallel workers and join their responses. The `fork` allows developers to spawn (fork) multiple workers within a Ballerina program and join the results from those workers. Here we used `{qatarWorker, asianaWorker, emiratesWorker};` as the `wait` condition, which means the program waits for all the workers to respond.

Let's now look at how the travel agency service integrates with the hotel reservation service. Similar to the above scenario, the travel agency service sends requests to all three available resources in parallel and waits for all of them to respond. Once it receives the responses, it selects the hotel that is closest to the client's preferred location. Refer to the following code snippet.

```ballerina
// Hotel reservation
// Call Hotel reservation service and consume different resources in parallel to check different hotels
// fork to run parallel workers and join the results
fork {
    // Worker to communicate with hotel 'Miramar'
    worker miramar returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint hotelPayload);
        // Send a POST request to 'Asiana' and get the results
        var respWorkerMiramar = hotelEP->post("/miramar", outReq);
        // Reply to the join block from this worker - Send the response from 'Asiana'
        if (respWorkerMiramar is http:Response) {
            return respWorkerMiramar;
        }
        return;
    }

    // Worker to communicate with hotel 'Aqueen'
    worker aqueen returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint hotelPayload);
        // Send a POST request to 'Aqueen' and get the results
        var respWorkerAqueen = hotelEP->post("/aqueen", outReq);
        // Reply to the join block from this worker - Send the response from 'Aqueen'
        if (respWorkerAqueen is http:Response) {
            return respWorkerAqueen;
        }
        return;
    }

    // Worker to communicate with hotel 'Elizabeth'
    worker elizabeth returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint hotelPayload);
        // Send a POST request to 'Elizabeth' and get the results
        var respWorkerElizabeth = hotelEP->post("/elizabeth", outReq);
        // Reply to the join block from this worker - Send the response from 'Elizabeth'
        if (respWorkerElizabeth is http:Response) {
            return respWorkerElizabeth;
        }
        return;
    }
}

record{http:Response? miramar; http:Response? aqueen; http:Response? elizabeth;} hotelResponses =
        wait{miramar, aqueen, elizabeth};

    // Wait until the responses received from all the workers running in parallel
    int miramarDistance = -1;
    int aqueenDistance = -1;
    int elizabethDistance = -1;

    // Get the response and distance to the preferred location from the hotel 'Miramar'
    var responseMiramar = hotelResponses["miramar"];
    if (responseMiramar is http:Response) {
        var mirmarPayload = responseMiramar.getJsonPayload();
        if (mirmarPayload is json) {
            miramarJsonResponse = mirmarPayload;
            var miramarDistanceResult = miramarJsonResponse.DistanceToLocation;
            if (miramarDistanceResult is int) {
                miramarDistance = miramarDistanceResult;
            }
        }
    }

    // Get the response and distance to the preferred location from the hotel 'Aqueen'
    var responseAqueen = hotelResponses["aqueen"];
    if (responseAqueen is http:Response) {
        var aqueenPayload = responseMiramar.getJsonPayload();
        if (aqueenPayload is json) {
            aqueenJsonResponse = aqueenPayload;
            var aqueenDistanceResult = aqueenJsonResponse.DistanceToLocation;
            if (aqueenDistanceResult is int) {
                aqueenDistance = aqueenDistanceResult;
            }
        }
    }

    // Get the response and distance to the preferred location from the hotel 'Elizabeth'
    var responseElizabeth = hotelResponses["elizabeth"];
    if (responseElizabeth is http:Response) {
        var elizabethPayload = responseMiramar.getJsonPayload();
        if (elizabethPayload is json) {
            elizabethJsonResponse = elizabethPayload;
            var elizabethDistanceResult = elizabethJsonResponse.DistanceToLocation;
            if (elizabethDistanceResult is int) {
                elizabethDistance = elizabethDistanceResult;
            }
        }
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
```

Let's next look at how the travel agency service integrates with the car rental service. The travel agency service sends requests to all three car rental providers in parallel and gets only the first one to respond. Refer to the following code snippet.

```ballerina
// Car rental
// Call Car rental service and consume different resources in parallel to check different companies
// Fork to run parallel workers and join the results
fork {
    // Worker to communicate with Company 'DriveSg'
    worker driveSg returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint vehiclePayload);
        // Send a POST request to 'DriveSg' and get the results
        var respWorkerDriveSg = carRentalEP->post("/driveSg", outReq);
        // Reply to the join block from this worker - Send the response from 'DriveSg'
        if (respWorkerDriveSg is http:Response) {
            return respWorkerDriveSg;
        }
        return;
    }

    // Worker to communicate with Company 'DreamCar'
    worker dreamCar returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint vehiclePayload);
        // Send a POST request to 'DreamCar' and get the results
        var respWorkerDreamCar = carRentalEP->post("/dreamCar", outReq);
        if (respWorkerDreamCar is http:Response) {
        // Reply to the join block from this worker - Send the response from 'DreamCar'
            return respWorkerDreamCar;
        }
        return;
    }

    // Worker to communicate with Company 'Sixt'
    worker sixt returns http:Response? {
        http:Request outReq = new;
        // Out request payload
        outReq.setJsonPayload(untaint vehiclePayload);
        // Send a POST request to 'Sixt' and get the results
        var respWorkerSixt = carRentalEP->post("/sixt", outReq);
        // Reply to the join block from this worker - Send the response from 'Sixt'
        if (respWorkerSixt is http:Response) {
            return respWorkerSixt;
        }
        return;
    }
}
// Get the first responding worker
http:Response? vehicleResponse = wait driveSg | dreamCar | sixt;
if (vehicleResponse is http:Response) {
    var vehicleResponsePayload = vehicleResponse.getJsonPayload();
    if (vehicleResponsePayload is json) {
        jsonVehicleResponse = vehicleResponsePayload;
    }
}
```

Here we used `driveSg | dreamCar | sixt;` as the wait condition, which means the program gets results from only one worker, which responds first. Therefore, the travel agency service gets the car rental provider that responds first.

Finally, let's look at the structure of the `travel_agency_service_parallel.bal` file that is responsible for the Travel agency service.

##### travel_agency_service_parallel.bal

```ballerina
import ballerina/http;

// Service endpoint
listener http:Listener travelAgencyEP  = new(9090);

// Client endpoint to communicate with Airline reservation service
http:Client airlineEP = new("http://localhost:9091/airline");

// Client endpoint to communicate with Hotel reservation service
http:Client hotelEP = new("http://localhost:9092/hotel");

// Client endpoint to communicate with Car rental service
http:Client carRentalEP = new("http://localhost:9093/car");

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig { basePath: "/travel" }
service travelAgencyService on travelAgencyEP {
    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"],
        produces:["application/json"]}
    resource function arrangeTour (http:Caller caller, http:Request inRequest) {

        // Try parsing the JSON payload from the user request

        // Integration with Airline reservation service to reserve an airline

        // Integration with the hotel reservation service to reserve a hotel

        // Integration with the car rental service to rent a vehicle

        // Respond back to the client
    }
}
```

In the above code, `airlineEP` is the client endpoint defined through which the Ballerina service communicates with the external airline reservation service. The client endpoint defined to communicate with the external hotel reservation service is `hotelEP`. Similarly, `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

To see the complete implementation of the above file, refer to the [travel_agency_service_parallel.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/travel_agency/travel_agency_service_parallel.bal) file.


## Testing 

### Invoking the service

- Navigate to `parallel-service-orchestration/guide` and run the following commands in separate terminals to start all four HTTP services. This will start the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services in ports 9091, 9092, 9093 and 9090 respectively.

```bash
   $ ballerina run airline_reservation/
```
```bash
   $ ballerina run hotel_reservation/
```
```bash
   $ ballerina run car_rental/
```
```bash
   $ ballerina run travel_agency/
```
   
- Invoke the travel agency service by sending a POST request to arrange a tour.

```bash
   curl -v -X POST -d \
   '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo",
   "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json" 
```

- Travel agency service will send a response similar to the following:
    
```bash
    HTTP/1.1 200 OK
    
    ...
    
    {
        "Flight":
            {"Airline":"Emirates", "ArrivalDate":"12-03-2018", "ReturnDate":"13-04-2018", "From":"Colombo", "To":"Changi", "Price":273},
            
        "Hotel":
            {"HotelName":"Miramar", "FromDate":"12-03-2018", "ToDate":"13-04-2018", "DistanceToLocation":6},
            
         "Vehicle":
            {"Company":"DriveSG", "VehicleType":"Car", "FromDate":"12-03-2018", "ToDate":"13-04-2018", "PricePerDay":5}
    }
```    
   
### Writing unit tests 

In Ballerina, the unit test cases should be in the same module inside a folder named as `tests`.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. 
- Test functions should start with the prefix `test`.

See the below example.
```ballerina
   @test:Config
   function testTravelAgencyService () {
```
  
This guide contains unit test cases for each service implemented above. 

To run the tests, open your terminal and navigate to `parallel-service-orchestration/guide`, and run the following command.
```bash
   $ ballerina test
```

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/airline_reservation/tests/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/hotel_reservation/tests/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/car_rental/tests/car_rental_service_test.bal), and [travel_agency_service_parallel_test.bal](https://github.com/ballerina-guides/parallel-service-orchestration/blob/master/guide/tests/travel_agency_service_parallel_test.bal).


## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

- As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `parallel-service-orchestration/guide` and run the following command. 
```bash
   $ ballerina build <Module_Name>
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output. 
```
   Initiating service(s) in 'target/travel_agency.balx'
   [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 

Let's see how we can deploy the travel_agency_service we developed above on docker. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- In our travel_agency_service, we need to import  `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable docker image generation during the build time. 

##### travel_agency_service_parallel.bal
```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"travel_agency_service",
    tag:"v1.0"
}

@docker:Expose{}
listener http:Listener travelAgencyEP = new(9090);

// http:Client endpoint definitions to communicate with other services

@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {
``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to `parallel-service-orchestration/guide` and run the following command.  
  
```
   $ ballerina build travel_agency
  
   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
```

- Once you successfully build the docker image, you can run it with the `docker run` command that is shown in the previous step.  

```bash
   $ docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
```

   Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `$ docker ps`. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl command that we've used above. 
 
```bash
   curl -v -X POST -d \
   '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo",
   "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```


### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Let's now see how we can deploy our `travel_agency_service` on Kubernetes. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- First we need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable kubernetes deployment for the service we developed above. 

> NOTE: Linux users can use Minikube to try this out locally.

##### travel_agency_service_parallel.bal

```ballerina
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

// Service endpoint
listener http:Listener travelAgencyEP = new(9090);

// http:Client endpoint definitions to communicate with other services

@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {     
``` 

- Here we have used `@kubernetes:Deployment` to specify the docker image name which will be created as part of building this service. 
- We have also specified `@kubernetes:Service` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `@kubernetes:Ingress` which is the external interface to access your service (with path `/` and host name `ballerina.guides.io`)

If you are using Minikube, you need to set a couple of additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). The IP address of the cluster can be found by running the `minikube ip` command.

- Now you can build a Ballerina executable archive (`.balx`) of the service that we developed above, using the following command. This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```bash
   $ ballerina build travel_agency
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/kubernetes/travel_agency
```

- You can verify that the docker image that we specified in `@kubernetes:Deployment` is created, by using `docker images`. 
- Also the Kubernetes artifacts related our service, will be generated under `./target/kubernetes/travel_agency`. 
- Now you can create the Kubernetes deployment using:

```bash
   $ kubectl apply -f ./target/kubernetes/travel_agency
 
   deployment.extensions "ballerina-guides-travel-agency-service" created
   ingress.extensions "ballerina-guides-travel-agency-service" created
   service "ballerina-guides-travel-agency-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
```bash
   curl -v -X POST -d \
   '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo", 
   "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
   "http://localhost:<Node_Port>/travel/arrangeTour" -H "Content-Type:application/json"  
```
If you are using Minikube, you should use the IP address of the Minikube cluster obtained by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.

Ingress:

Add `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
```
   127.0.0.1        ballerina.guides.io
```

Access the service 
```bash
   curl -v -X POST -d \
   '{"ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", "From":"Colombo",
   "To":"Changi", "VehicleType":"Car", "Location":"Changi"}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"  
```


## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file and starting the ballerina service using it. A sample configuration file can be found in `parallel-service-orchestration/guide/travel_agency`.

```editorconfig
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

To start the ballerina service using the configuration file, run the following command

```bash
   $ ballerina run --config travel_agency/ballerina.conf <module_name>
```

### Tracing 
You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.
- Run Jaeger docker image using the following command

```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `parallel-service-orchestration/guide/` and start all services using the following command

```bash
   $ ballerina run --config travel_agency/ballerina.conf <module_name>
```
   
- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

- You should see the Jaeger UI as follows

   ![Jaeger UI](images/tracing-screenshot.png "Tracing Screenshot")
 

### Metrics
Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for travel_agency service.

- Set the below configurations in the `ballerina.conf` file in the project root.
```editorconfig
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
```

- Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
```yaml
   global:
   scrape_interval:     15s
   evaluation_interval: 15s

   scrape_configs:
    - job_name: 'prometheus'
   
   static_configs:
        - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
- Run the Prometheus docker image using the following command
```bash
   docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/tmp/prometheus.yml prom/prometheus
```

- Navigate to `parallel-service-orchestration/guide/` and start all services using the following command
```bash
   $ ballerina run --config travel_agency/ballerina.conf <module_name>
```

   NOTE: First start the `travel_agency` module since it's the main orchestrator for other services(also we are going
    to trace from travel agency service hence do not use the config file for other services)
   
- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

   NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
   
    - http_requests_total
    - http_response_time

- Promethues UI with metrics for parallel service orchestration
   
   ![promethues screenshot](images/metrics-screenshot.png "Prometheus UI")

### Logging
Ballerina has a log module for logging to the console. You can import ballerina/log module and start logging. The
following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `parallel-service-orchestration/guide`
```bash
   nohup ballerina run travel_agency/ &>> ballerina.log&
```

NOTE: This will write the console log to the `ballerina.log` file in the `parallel-service-orchestration/guide` directory

- Start Elasticsearch using the following command

```bash
   docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1 
```

NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch

```bash
   docker run -p 5601:5601 -h kibana --name kibana --link elasticsearch:elasticsearch \
   docker.elastic.co/kibana/kibana:6.5.1     
```

- Configure `logstash` to format the ballerina logs
   
i) Create a file named `logstash.conf` with the following content

```
input {  
    beats { 
        port => 5044 
    }  
}

filter {  
    grok {  
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

      
ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
iii) Start the `logstash` container, replace the `{SAMPLE_ROOT_DIRECTORY}` with your directory name

```bash
   docker run -h logstash --name logstash --link elasticsearch:elasticsearch -it --rm \
   -v {SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
   -p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
```
  
 - Configure filebeat to ship the ballerina logs
    
   i) Create a file named `filebeat.yml` with the following content
   
```yaml
   filebeat.prospectors:
       - type: log
   paths:
       - /usr/share/filebeat/ballerina.log
   output.logstash:
         hosts: ["logstash:5044"]
```

   ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT_DIRECTORY}\filebeat`   
        
  iii) Start the `logstash` container, replace the `{SAMPLE_ROOT_DIRECTORY}` with your directory name  
```bash
   docker run -v {SAMPLE_ROOT}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
   -v {SAMPLE_ROOT}/guide/ballerina.log:/usr/share/filebeat/ballerina.log \
   --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
```

- Access Kibana to visualize the logs using following URL
```
     http://localhost:5601 
```

NOTE: You may need to add `store` index pattern to kibana visualization tool to create a log visualization.
    
- Kibana log visualization for parallel service orchestration sample
 
     ![logging screenshot](images/logging-screenshot.png "Kibana UI")
     
