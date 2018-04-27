[![Build Status](https://travis-ci.org/pranavan15/service-composition.svg?branch=master)](https://travis-ci.org/pranavan15/service-composition)

# Service Composition

A service composition is an aggregate of services collectively composed to automate a particular task or business process. 

> This guide walks you through the process of implementing a service composition using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
To understanding how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the Travel agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/images/service-composition.svg)

Travel agency is the service that acts as the composition initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
 - [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping  "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
service-composition
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
      │   └── travel_agency_service.bal
      └── tests
          └── travel_agency_service_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `service-composition/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

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

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to book a flight ticket. To check the implementation of airline reservation service, see the [airline_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/airline_reservation/airline_reservation_service.bal) file.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. To check the implementation of hotel reservation service, see the [hotel_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/hotel_reservation/hotel_reservation_service.bal) file.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. To check the implementation of car rental service, see the [car_rental_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/car_rental/car_rental_service.bal) file.

If all services work successfully, the travel agency service confirms and arrange the complete tour for the user. The skeleton of `travel_agency_service.bal` file is attached below. Inline comments are added for better understanding.
Refer to the [travel_agency_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/travel_agency/travel_agency_service.bal) to see the complete implementation of the travel agency service.

##### travel_agency_service.bal

```ballerina
package travel_agency;

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
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina run airline_reservation/
```
```
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina run hotel_reservation/
```
```
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina run car_rental/
```
```
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina run travel_agency/
```
   
- Invoke the travel agency service by sending a POST request to arrange a tour.

```
    curl -v -X POST -d \
    '{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018",
     "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
     "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```

  Travel agency service will send a response similar to the following:
    
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

To run the unit tests, go to the guides directory and run the following command
```
   <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina test
```

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/airline_reservation/test/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/hotel_reservation/test/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/car_rental/test/car_rental_service_test.bal) and [travel_agency_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guides/travel_agency/test/travel_agency_service_test.bal).


## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows.

Building 
```
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina build <Package_Name>
```

Running
```
    <SAMPLE_ROOT_DIRECTORY>/guides$ ballerina run target/<Exec_Archive_File_Name>
```

### Deploying on Docker

You can run the services that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 
Let's see how we can deploy the travel_agency_service we developed above on docker. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- In our travel_agency_service, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### travel_agency_service.bal
```ballerina
package travel_agency;

import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"travel_agency_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener travelAgencyEP {
    port:9090
};

// http:Client endpoint definitions to communicate with other services

@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP { 
``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/guides/` folder and run the following command.  
  
```
  $ballerina build travel_agency
  
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
package travel_agency;

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
- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
  $ballerina build travel_agency
  
  Run following command to deploy kubernetes artifacts:  
  kubectl apply -f ./target/travel_agency/kubernetes
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``. 
- Also the Kubernetes artifacts related our service, will be generated under `` ./target/travel_agency/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
 $ kubectl apply -f ./target/travel_agency/kubernetes 
 
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
  "http://localhost:<Node_Port>/travel/arrangeTour" -H "Content-Type:application/json"  
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

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file in `service-composition/guide/`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations default values are load as the other configuration parameters of metrics and tracing.

### Tracing 

You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.

- You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described above.
```
   [b7a.observability]

   [b7a.observability.tracing]
   enabled=true
   name="jaeger"

   [b7a.observability.tracing.jaeger]
   reporter.hostname="localhost"
   reporter.port=5775
   sampler.param=1.0
   sampler.type="const"
   reporter.flush.interval.ms=2000
   reporter.log.spans=true
   reporter.max.buffer.spans=1000
```

- Run Jaeger docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `service-composition/guide` and run the `travel_agency_service` using following command 
```
   $ ballerina run travel_agency/
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for travel_agency service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

```ballerina
   [b7a.observability.metrics]
   enabled=true
   provider="micrometer"

   [b7a.observability.metrics.micrometer]
   registry.name="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9700
   hostname="0.0.0.0"
   descriptions=false
   step="PT1M"
```

- Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
- Run the Prometheus docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `service-composition/guide`
```
   $ nohup ballerina run travel_agency/ &>> ballerina.log&
```
   NOTE: This will write the console log to the `ballerina.log` file in the `service-composition/guide` directory

- Start Elasticsearch using the following command

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```

- Configure logstash to format the ballerina logs

i) Create a file named `logstash.conf` with the following content
```
input {  
 beats{ 
     port => 5044 
 }  
}

filter {  
 grok{  
     match => { 
	 "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	 \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }  
 }  
}   

output {  
 elasticsearch{  
     hosts => "elasticsearch:9200"  
     index => "store"  
     document_type => "store_logs"  
 }  
}  
```

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
  
 - Configure filebeat to ship the ballerina logs
    
i) Create a file named `filebeat.yml` with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of filebeat.yml file using `$chmod go-w filebeat.yml` 

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
iii) Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/travel_agency/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```
  