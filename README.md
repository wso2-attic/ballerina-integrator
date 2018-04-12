# Service Composition

A service composition is an aggregate of services collectively composed to automate a particular task or business process. 

> This guide walks you through the process of implementing a service composition using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build
To understanding how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the Travel agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/images/service_composition.png)

Travel agency is the service that acts as the composition initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service

### Before you begin
#### Understand the package structure
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


Once you created your package structure, go to the sample src directory and run the following command to initialize your Ballerina project.

```bash
  $ballerina init
```

The above command will initialize the project with a `Ballerina.toml` file and `.ballerina` implementation directory that contain a list of packages in the current directory.

### Implementation

Let's look at the implementation of the travel agency service, which acts as the composition initiator.

Arranging a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:

```
{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", 
 "Preference":<service_dependent_preference>};
```

Sample response payload:

```
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

import ballerina/http;

// Service endpoint
endpoint http:Listener travelAgencyEP {
    port:9090
};

// Client endpoint to communicate with Airline reservation service
endpoint http:Client airlineReservationEP {
    targets:[{url:"http://localhost:9091/airline"}]
};

// Client endpoint to communicate with Hotel reservation service
endpoint http:Client hotelReservationEP {
    targets:[{url:"http://localhost:9092/hotel"}]
};

// Client endpoint to communicate with Car rental service
endpoint http:Client carRentalEP {
    targets:[{url:"http://localhost:9093/car"}]
};

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {

// Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"],
        produces:["application/json"]}
    arrangeTour(endpoint client, http:Request inRequest) {
        http:Response outResponse;

        // JSON payload format for an HTTP OUT request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"",
            "Preference":""};

        // Try parsing the JSON payload from the user request

        // Reserve airline ticket for the user by calling the airline reservation service

        // Reserve hotel room for the user by calling the hotel reservation service

        // Renting car for the user by calling the car rental service


        // If all three response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!"});
        _ = client -> respond(outResponse);
    }
}
```

Let's now look at the code segment that is responsible for communicating with the airline reservation service. 

```ballerina
// Reserve airline ticket for the user by calling Airline reservation service
http:Request outReqAirline;
http:Response inResAirline;
// construct the payload
json outReqPayloadAirline = outReqPayload;
outReqPayloadAirline.Preference = airlinePreference;
outReqAirline.setJsonPayload(outReqPayloadAirline);

// Send a post request to airline service with appropriate payload and get response
inResAirline = check airlineReservationEP -> post("/reserve", outReqAirline);

// Get the reservation status
var airlineResPayload = check inResAirline.getJsonPayload();
string airlineStatus = airlineResPayload.Status.toString() but { () => "Failed" };
// If reservation status is negative, send a failure response to user
if (airlineStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
            "Provide a valid 'Preference' for 'Airline' and try again"});
    _ = client -> respond(outResponse);
    done;
}
```

The above code shows how the travel agency service initiates a request to the airline reservation service to book a flight ticket. `airlineReservationEP` is the client endpoint you defined through which the Ballerina service communicates with the external airline reservation service.


Let's now look at the code segment that is responsible for communicating with the hotel reservation service. 

```ballerina
// Reserve hotel room for the user by calling Hotel reservation service
http:Request outReqHotel;
http:Response inResHotel;
// construct the payload
json outReqPayloadHotel = outReqPayload;
outReqPayloadHotel.Preference = hotelPreference;
outReqHotel.setJsonPayload(outReqPayloadHotel);

// Send a post request to hotel service with appropriate payload and get response
inResHotel = check hotelReservationEP -> post("/reserve", outReqHotel);

// Get the reservation status
var hotelResPayload = check inResHotel.getJsonPayload();
string hotelStatus = hotelResPayload.Status.toString() but { () => "Failed" };
// If reservation status is negative, send a failure response to user
if (hotelStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
            "Provide a valid 'Preference' for 'Accommodation' and try again"});
    _ = client -> respond(outResponse);
    done;
}
```
The travel agency service communicates with the hotel reservation service to book a room for the client as shown above. The client endpoint defined for this external service call is `hotelReservationEP`.

Finally, let's look at the code segment that is responsible for communicating with the car rental service. 

```ballerina
// Renting car for the user by calling Car rental service
http:Request outReqCar;
http:Response inResCar;
// construct the payload
json outReqPayloadCar = outReqPayload;
outReqPayloadCar.Preference = carPreference;
outReqCar.setJsonPayload(outReqPayloadCar);

// Send a post request to car rental service with appropriate payload and get response
inResCar = check carRentalEP -> post("/rent", outReqCar);

// Get the rental status
var carResPayload = check inResCar.getJsonPayload();
string carRentalStatus = carResPayload.Status.toString() but { () => "Failed" };
// If rental status is negative, send a failure response to user
if (carRentalStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to rent car! " +
            "Provide a valid 'Preference' for 'Car' and try again"});
    _ = client -> respond(outResponse);
    done;
}
```

As shown above, the travel agency service rents a car for the requested user by calling the car rental service. `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

## Testing 

### Try it out

- Start all four HTTP services by entering the following commands in separate terminals. This will start the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services in ports 9091, 9092, 9093 and 9090 respectively.

```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run AirlineReservation/
```
```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run HotelReservation/
```
```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run CarRental/
```
```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run TravelAgency/
```
   
- Invoke the `travelAgencyService` by sending a POST request to arrange a tour.

```
    curl -v -X POST -d \
    '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
     "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
     "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```

  The `travelAgencyService` sends a response similar to the following:
    
```
     < HTTP/1.1 200 OK
    {"Message":"Congratulations! Your journey is ready!!"}
``` 
   
   
### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'.  When writing the test functions the below convention should be followed.
* Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
    @test:Config
    function testTravelAgencyService () {
```
  
This guide contains unit test cases for each service implemented above. 

To run the unit tests, go to the sample src directory and run the following command
```
   <SAMPLE_ROOT_DIRECTORY>/src$ ballerina test
```

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/AirlineReservation/test/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/HotelReservation/test/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/CarRental/test/car_rental_service_test.bal) and [travel_agency_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/src/TravelAgency/test/travel_agency_service_test.bal).


## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows.

Building 
```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina build <Package_Name>
```

Running
```
    <SAMPLE_ROOT_DIRECTORY>/src$ ballerina run target/<Exec_Archive_File_Name>
```

### Deploying on Docker

You can run the services that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 
Let's see how we can deploy the travel_agency_service we developed above on docker. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- In our travel_agency_service, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### travel_agency_service.bal
```ballerina
package TravelAgency;

import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"travel_agency_service",
    tag:"v1.0"
}

endpoint http:Listener travelAgencyEP {
    port:9090
};

// http:Client endpoint definitions to communicate with other services

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
    '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
    "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
    "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```


### Deploying on Kubernetes

- You can run the services that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, 
with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. 
So you don't need to explicitly create docker images prior to deploying it on Kubernetes.   
Let's see how we can deploy the travel_agency_service we developed above on kubernetes. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- We need to import `` import ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### travel_agency_service.bal

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

endpoint http:Listener travelAgencyEP {
    port:9090
};

// http:Client endpoint definitions to communicate with other services

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
  '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
  "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
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
 '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
 "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
 "http://ballerina.guides.io/travel/arrangeTour" -H "Content-Type:application/json" 
```
