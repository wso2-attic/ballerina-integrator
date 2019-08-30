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
To understand how you can build a service composition using Ballerina, let's consider a real-world use case of a Travel agency that arranges complete tours for users. A tour package includes airline ticket reservation, hotel room reservation and car rental. Therefore, the Travel agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/resources/service-composition.svg)

Travel agency is the service that acts as the composition initiator. The other three services are external services that the travel agency service calls to do airline ticket booking, hotel reservation and car rental. These are not necessarily Ballerina services and can theoretically be third-party services that the travel agency service calls to get things done. However, for the purposes of setting up this scenario and illustrating it in this guide, these third-party services are also written in Ballerina.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

### Optional requirements
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following module structure
 for this guide.

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
      └── travel_agency
          ├── travel_agency_service.bal
          └── tests
              └── travel_agency_service_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `service-composition/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the service

Let's look at the implementation of the travel agency service, which acts as the composition initiator.

Arranging a complete tour travel agency service requires communicating with three other services: airline reservation, hotel reservation, and car rental. All these services accept POST requests with appropriate JSON payloads and send responses back with JSON payloads. Request and response payloads are similar for all three backend services.

Sample request payload:
```bash
{"Name":"Bob", "ArrivalDate":"12-03-2018", "DepartureDate":"13-04-2018", 
 "Preference":<service_dependent_preference>};
```

Sample response payload:

```bash
{"Status":"Success"}
```

When a client initiates a request to arrange a tour, the travel agency service first needs to communicate with the airline reservation service to book a flight ticket. To check the implementation of airline reservation service, see the [airline_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/airline_reservation/airline_reservation_service.bal) file.

Once the airline ticket reservation is successful, the travel agency service needs to communicate with the hotel reservation service to reserve hotel rooms. To check the implementation of hotel reservation service, see the [hotel_reservation_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/hotel_reservation/hotel_reservation_service.bal) file.

Finally, the travel agency service needs to connect with the car rental service to arrange internal transports. To check the implementation of car rental service, see the [car_rental_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/car_rental/car_rental_service.bal) file.

If all services work successfully, the travel agency service confirms and arrange the complete tour for the user. The skeleton of `travel_agency_service.bal` file is attached below. Inline comments are added for better understanding.
Refer to the [travel_agency_service.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/travel_agency/travel_agency_service.bal) to see the complete implementation of the travel agency service.

##### travel_agency_service.bal

```ballerina
import ballerina/http;

// Service endpoint
listener http:Listener travelAgencyEP = new(9090);

// Client endpoint to communicate with Airline reservation service
http:Client airlineReservationEP = new("http://localhost:9091/airline");

// Client endpoint to communicate with Hotel reservation service
http:Client hotelReservationEP = new("http://localhost:9092/hotel");

// Client endpoint to communicate with Car rental service
http:Client carRentalEP = new("http://localhost:9093/car");

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {

    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"],
        produces:["application/json"]}
    resource function arrangeTour(http:Caller caller, http:Request inRequest) {
        http:Response outResponse = new;
        json inReqPayload = {};

        // JSON payload format for an HTTP OUT request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"",
            "Preference":""};

        // Try parsing the JSON payload from the user request

        // Reserve airline ticket for the user by calling airline reservation service

        // Reserve hotel room for the user by calling hotel reservation service

        // Renting car for the user by calling the car rental service

        // If all three response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congrats! Your journey is ready!"});
        var result = caller->respond(outResponse);
        handleError(result);
    }
}
```

Let's now look at the code segment that is responsible for parsing the JSON payload from the user request.

```ballerina
// Try parsing the JSON payload from the user request
var payload = inRequest.getJsonPayload();
if (payload is json) {
    // Valid JSON payload
    inReqPayload = payload;
} else {
    // NOT a valid JSON payload
    outResponse.statusCode = 400;
    outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
    var result = caller->respond(outResponse);
    handleError(result);
    return;
}

outReqPayload.Name = inReqPayload.Name;
outReqPayload.ArrivalDate = inReqPayload.ArrivalDate;
outReqPayload.DepartureDate = inReqPayload.DepartureDate;
json airlinePreference = inReqPayload.Preference.Airline;
json hotelPreference = inReqPayload.Preference.Accommodation;
json carPreference = inReqPayload.Preference.Car;

// If payload parsing fails, send a "Bad Request" message as the response
if (outReqPayload.Name == () || outReqPayload.ArrivalDate == () ||
    outReqPayload.DepartureDate == () || airlinePreference == () ||
    hotelPreference == () || carPreference == ()) {
    outResponse.statusCode = 400;
    outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
    var result = caller->respond(outResponse);
    handleError(result);
    return;
}
```

The above code shows how the request JSON payload is parsed to create JSON literals required for further processing.

Let's now look at the code segment that is responsible for communicating with the airline reservation service. 

```ballerina
// Reserve airline ticket for the user by calling Airline reservation service
// construct the payload
json outReqPayloadAirline = outReqPayload;
outReqPayloadAirline.Preference = airlinePreference;

// Send a post request to airline service with appropriate payload and get response
http:Response inResAirline = check airlineReservationEP->post("/reserve",
                                                    untaint outReqPayloadAirline);

// Get the reservation status
var airlineResPayload = check inResAirline.getJsonPayload();
string airlineStatus = airlineResPayload.Status.toString();
// If reservation status is negative, send a failure response to user
if (airlineStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
            "Provide a valid 'Preference' for 'Airline' and try again"});
    var result = caller->respond(outResponse);
    handleError(result);
    return;
}
```

The above code shows how the travel agency service initiates a request to the airline reservation service to book a flight ticket. `airlineReservationEP` is the client endpoint you defined through which the Ballerina service communicates with the external airline reservation service.


Let's now look at the code segment that is responsible for communicating with the hotel reservation service. 

```ballerina
// Reserve hotel room for the user by calling Hotel reservation service
// construct the payload
json outReqPayloadHotel = outReqPayload;
outReqPayloadHotel.Preference = hotelPreference;

// Send a post request to hotel service with appropriate payload and get response
http:Response inResHotel = check hotelReservationEP->post("/reserve",
                                                    untaint outReqPayloadHotel);

// Get the reservation status
var hotelResPayload = check inResHotel.getJsonPayload();
string hotelStatus = hotelResPayload.Status.toString();
// If reservation status is negative, send a failure response to user
if (hotelStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
            "Provide a valid 'Preference' for 'Accommodation' and try again"});
    var result = caller->respond(outResponse);
    handleError(result);
    return;
}
```

The travel agency service communicates with the hotel reservation service to book a room for the client as shown above. The client endpoint defined for this external service call is `hotelReservationEP`.

Finally, let's look at the code segment that is responsible for communicating with the car rental service. 

```ballerina
// Renting car for the user by calling Car rental service
// construct the payload
json outReqPayloadCar = outReqPayload;
outReqPayloadCar.Preference = carPreference;

// Send a post request to car rental service with appropriate payload and get response
http:Response inResCar = check carRentalEP->post("/rent", untaint outReqPayloadCar);

// Get the rental status
var carResPayload = check inResCar.getJsonPayload();
string carRentalStatus = carResPayload.Status.toString();
// If rental status is negative, send a failure response to user
if (carRentalStatus.equalsIgnoreCase("Failed")) {
    outResponse.setJsonPayload({"Message":"Failed to rent car! " +
            "Provide a valid 'Preference' for 'Car' and try again"});
    var result = caller->respond(outResponse);
    handleError(result);
    return;
}
```

As shown above, the travel agency service rents a car for the requested user by calling the car rental service. `carRentalEP` is the client endpoint defined to communicate with the external car rental service.

## Testing 

### Invoking the service

- Navigate to `service-composition/guide` and run the following commands in separate terminals to start all four HTTP services. This starts the `Airline Reservation`, `Hotel Reservation`, `Car Rental` and `Travel Agency` services on ports 9091, 9092, 9093 and 9090 respectively.

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
   curl -v -X POST -d '{"Name":"Bob", "ArrivalDate":"12-03-2018",
   "DepartureDate":"13-04-2018", "Preference":{"Airline":"Business", 
   "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```

  Travel agency service sends a response similar to the following:
    
```bash
   < HTTP/1.1 200 OK
   {"Message":"Congratulations! Your journey is ready!!"}
``` 
      
### Writing unit tests 

In Ballerina, the unit test cases should be in the same module inside a folder named as 'tests'.  When writing the test
functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testTravelAgencyService () {
```
  
This guide contains unit test cases for each service implemented above. 

To run the tests, open your terminal and navigate to `service-composition/guide`, and run the following command.
```bash
   $ ballerina test
```

To check the implementations of these test files, refer to the [airline_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/airline_reservation/tests/airline_reservation_service_test.bal), [hotel_reservation_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/hotel_reservation/tests/hotel_reservation_service_test.bal), [car_rental_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/car_rental/tests/car_rental_service_test.bal) and [travel_agency_service_test.bal](https://github.com/ballerina-guides/service-composition/blob/master/guide/tests/travel_agency_service_test.bal).

## Deployment

Once you are done with the development, you can deploy the services using any of the methods that are listed below. 

### Deploying locally

- As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `service-composition/guide` and run the following command. 
```bash
   $ ballerina build <Module_Name>
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service shows us something similar to the following output. 
```
   Initiating service(s) in 'target/travel_agency.balx'
   [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a Docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers, you just need to put the corresponding Docker annotations on your service code.

Let's see how we can deploy the travel_agency_service we developed above on Docker. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running.

- In our travel_agency_service, we need to import  `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation during the build time.

##### travel_agency_service.bal
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

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This creates the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `service-composition/guide` and run the following command.
  
```
   $ ballerina build travel_agency
  
   Run following command to start Docker container:
   docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
```

- Once you successfully build the Docker image, you can run it with the `` docker run`` command that is shown in the previous step.

```bash
   $ docker run -d -p 9090:9090 ballerina.guides.io/travel_agency_service:v1.0
```

   Here we run the Docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port.

- Verify Docker container is running with the use of `` $ docker ps``. The status of the Docker container should be shown as 'Up'.
- You can access the service using the same curl commands that we've used above. 
 
```bash
   curl -v -X POST -d '{"Name":"Bob", "ArrivalDate":"12-03-2018",
   "DepartureDate":"13-04-2018", "Preference":{"Airline":"Business", 
   "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
   "http://localhost:9090/travel/arrangeTour" -H "Content-Type:application/json"
```


### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it takes care of the creation of the Docker images. So you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs.

- Let's now see how we can deploy our `travel_agency_service` on Kubernetes. When invoking this service make sure that the other three services (airline_reservation, hotel_reservation, and car_rental) are also up and running. 

- First we need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable kubernetes deployment for the service we developed above. 

> NOTE: Linux users can use Minikube to try this out locally.

##### travel_agency_service.bal

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

endpoint http:Listener travelAgencyEP {
    port:9090
};

// http:Client endpoint definitions to communicate with other services

@http:ServiceConfig {basePath:"/travel"}
service travelAgencyService on travelAgencyEP {    
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the Docker image name that is created as part of building this service.
- We have also specified `` @kubernetes:Service `` so that it creates a Kubernetes service, which exposes the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

If you are using Minikube, you need to set a couple of additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). The IP address of the cluster can be found by running the `minikube ip` command.
 
- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This creates the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build travel_agency
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/travel_agency/kubernetes
```

- You can verify that the Docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``.
- Also the Kubernetes artifacts related to our service are generated under `` ./target/travel_agency/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```bash
   $ kubectl apply -f ./target/travel_agency/kubernetes 
 
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
   curl -v -X POST -d '{"Name":"Bob", "ArrivalDate":"12-03-2018",
   "DepartureDate":"13-04-2018", "Preference":{"Airline":"Business", 
   "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
   "http://localhost:<Node_Port>/travel/arrangeTour" -H "Content-Type:application/json"  
```
If you are using Minikube, you should use the IP address of the Minikube cluster obtained by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.

Ingress:

Add `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
``` 
   127.0.0.1 ballerina.guides.io
```

Access the service 
```bash
   curl -v -X POST -d '{"Name":"Bob", "ArrivalDate":"12-03-2018",
   "DepartureDate":"13-04-2018", "Preference":{"Airline":"Business", 
   "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}}' \
   "http://ballerina.guides.io/travel/arrangeTour" -H "Content-Type:application/json" 
```

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file and starting the ballerina service using it. A sample configuration file can be found in `service-composition/guide/travel_agency/`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

To start the ballerina service using the configuration file, run the following command

```
   $ ballerina run --config travel_agency/ballerina.conf travel_agency
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

- Run Jaeger Docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
   -p16686:16686 p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `service-composition/guide` and run the `travel_agency_service` using the following command
```
   $ ballerina run --config travel_agency/ballerina.conf travel_agency
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with ballerina. We use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for travel_agency service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
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

   NOTE : Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`
   
- Run the Prometheus Docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `service-composition/guide` and run the `travel_agency_service` using the following command
```
  $ ballerina run --config travel_agency/ballerina.conf travel_agency
```

- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

NOTE:  Ballerina, by default has following metrics for HTTP server connector. You can enter following expression in Prometheus UI
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log module for logging to the console. You can import ballerina/log module and start logging. The
following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `service-composition/guide`
```
   $ nohup ballerina run travel_agency/ &>> ballerina.log&
```
   NOTE: This writes the console log to the `ballerina.log` file in the `service-composition/guide` directory

- Start Elasticsearch using the following command

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.5.1   
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
-p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
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
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```
  
