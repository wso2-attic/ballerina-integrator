# Backend for Frontend

Backend for frontend(BFF) is a service design pattern that provides the core idea to create separate back-end services for specific front-end applications. This pattern allows you to have separate back-end service layers(shim) depending on the user experience you expect to have in the front-end application. The BFF design pattern has its own advantages and disadvantages. The usage of the pattern depends on your use case and requirements. For more information on the BFF design pattern, see [(https://samnewman.io/patterns/architectural/bff/)] and [(http://philcalcado.com/2015/09/18/the_back_end_for_front_end_pattern_bff.html)]. 

> Let’s take a look at a sample scenario to understand how to apply the BFF design pattern when working with Ballerina. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build
Let’s take a real world use case of an online healthcare management system to understand how BFF works. Assume that the healthcare provider needs to have a desktop application as well as a mobile application to provide users a quality online experience. The manner in which information is displayed to a user can vary depending on whether the user signs in to the desktop application or mobile application. This is because the resource limitations such as screen size, battery life and data usage in mobile device can cause the mobile application to show minimal viable information to an end user, whereas when it comes to desktop applications, it is possible to display more information and allow multiple network calls to get the required information. The difference in requirements when it comes to each application leads to the need to have a separate BFF for each application. Here, the BFF layer will consumes existing downstream services and act as a shim to translate the required information depending on the user experience.  

The following diagram illustrates the scenario:

![BFF Design](resources/backend-for-frontend.svg "BFF Design")

For this scenario, you need to have two applications called desktop application and mobile application. For each application, there should be a specific back-end service (BFF) called desktop BFF and mobile BFF respectively. These BFFs should consume a set of downstream services called appointment management service, medical record management service, notification management service and message management service.  In this guide, Ballerina is used to build both the BFF layer and the downstream service layer.

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

### Optional requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from git and skip the [Implementation](#implementation) instructions.

### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:

```
backend-for-frontend
  └── guide
      ├── appointment_mgt
      │   ├── appointment_mgt_service.bal
      │   └── tests
      │       └── appointment_mgt_service_test.bal
      ├── medical_record_mgt
      │   ├── medical_record_mgt_service.bal
      │   └── tests
      │       └── medical_record_mgt_service_test.bal
      ├── notification_mgt
      │   ├── notification_mgt_service.bal
      │   └── tests
      │       └── notification_mgt_service_test.bal
      ├── message_mgt
      │   ├── message_mgt_service.bal
      │   └── tests
      │       └── message_mgt_service_test.bal
      ├── mobile_bff
      │   ├── mobile_bff_service.bal
      │   └── tests
      │       └── mobile_bff_service_test.bal
      ├── desktop_bff
      │   ├── desktop_bff_service.bal
      │   └── tests
      │       └── desktop_bff_service_test.bal
      └── sample_data_publisher
          └── sample_data_publisher.bal
```

- Create the above directories in your local machine and also create the empty `.bal` files.
- Then open a terminal, navigate to `backend-for-frontend/guide`, and then run the Ballerina project initializing toolkit.

```bash
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the services.

### Developing the service

First let’s implement the set of downstream services.  

Appointment Management Service (appointment_mgt_service) is a REST API to manage health appointments for members. For demonstration purpose it should have an in-memory map to hold appointment data, and should also have the capability to add appointments as well as retrieve appointments. 

##### Skeleton code for appointment_mgt_service.bal
```ballerina
import ballerina/http;

endpoint http:Listener listener {
   port: 9092
};

// Appointment management is done using an in-memory map.
// Add some sample appointments to 'appointmentMap' at startup.
map<json> appointmentMap;

// RESTful service.
@http:ServiceConfig { basePath: "/appointment-mgt" }
service<http:Service> appointment_service bind listener {

   @http:ResourceConfig {
       methods: ["POST"],
       path: "/appointment"
   }
   addAppointment(endpoint client, http:Request req) {
    // implementation  
   }

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/appointment/list"
   }
   getAppointments(endpoint client, http:Request req) {
    // implementation       
   }

}
```

Medical Record Management Service (medical_record_mgt_service) is a REST API to manage medical records for members. For demonstration purpose it should have an in-memory map to hold medical records, and should also have the capability to add medical records and retrieve medical records. 

##### Skeleton code for medical_record_mgt_service.bal
```ballerina
import ballerina/http;

endpoint http:Listener listener {
   port: 9093
};

// Medical Record management is done using an in-memory map.
// Add some sample Medical Records to 'medicalRecordMap' at startup.
map<json> medicalRecordMap;

// RESTful service.
@http:ServiceConfig { basePath: "/medical-records" }
service<http:Service> medical_record_service bind listener {

   @http:ResourceConfig {
       methods: ["POST"],
       path: "/medical-record"
   }
   addMedicalRecord(endpoint client, http:Request req) {
       // Implementation 
   }
 
   @http:ResourceConfig {
       methods: ["GET"],
       path: "/medical-record/list"
   }
   getMedicalRecords(endpoint client, http:Request req) {
       // Implementation 
   }
 
}

```

Notification Management Service (notification_mgt_service) is a REST API to manage notifications. For demonstration purpose it should have an in-memory map to hold notifications,and should also have the capability to add notifications and retrieve notifications. 

##### Skeleton code for notification_mgt_service.bal
```ballerina
import ballerina/http;

endpoint http:Listener listener {
   port: 9094
};

// Notification management is done using an in-memory map.
// Add some sample notifications to 'notificationMap' at startup.
map<json> notificationMap;


// RESTful service.
@http:ServiceConfig { basePath: "/notification-mgt" }
service<http:Service> notification_service bind listener {

   @http:ResourceConfig {
       methods: ["POST"],
       path: "/notification"
   }
   addNotification(endpoint client, http:Request req) {
       // Implementation 
   }


   @http:ResourceConfig {
       methods: ["GET"],
       path: "/notification/list"
   }
   getNotifications(endpoint client, http:Request req) {
       // Implementation 
   }


}

```

Message Management Service (message_mgt_service) is a REST API to manage messages. For demonstration purpose it should have an in-memory map to hold messages, and should also have the capability to add messages, retrieve all messages as well as retrieve unread messages. 

##### Skeleton code for message_mgt_service.bal
```ballerina

import ballerina/http;

endpoint http:Listener listener {
   port: 9095
};

// Message management is done using an in-memory map.
// Add some sample messages to 'messageMap' at startup.
map<json> messageMap;


// RESTful service.
@http:ServiceConfig { basePath: "/message-mgt" }
service<http:Service> message_service bind listener {

   @http:ResourceConfig {
       methods: ["POST"],
       path: "/message"
   }
   addMessage(endpoint client, http:Request req) {

      // Implementation 
   }

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/message/list"
   }
   getMessages(endpoint client, http:Request req) {
       // Implementation 
   }

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/unread-message/list"
   }
   getUnreadMessages(endpoint client, http:Request req) {
       // Implementation 

}

```

Now let’s move to the key implementation of BFF services. 

Mobile BFF(mobile_bff_service) is a shim used to support Mobile user experience in this use case. When loading mobile application home page, it calls a single resource in Mobile BFF and retrieve appointments, medical records and messages. This will reduce number of backend calls and help to load the home pages in much efficient way. Also the mobile apps having different method of sending notifications hence home page loading does not need to involve notification management service. 

##### Skeleton code for mobile_bff_service.bal
```ballerina

import ballerina/http;

endpoint http:Listener listener {
   port: 9090
};

// Client endpoint to communicate with appointment management service
endpoint http:Client appointmentEP {
   url: "http://localhost:9092/appointment-mgt"
};

// Client endpoint to communicate with medical record service
endpoint http:Client medicalRecordEP {
   url: "http://localhost:9093/medical-records"
};

// Client endpoint to communicate with message management service
endpoint http:Client messageEP {
   url: "http://localhost:9095/message-mgt"
};


// RESTful service.
@http:ServiceConfig { basePath: "/mobile-bff" }
service<http:Service> mobile_bff_service bind listener {

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/profile"
   }
   getUserProfile(endpoint client, http:Request req) {

       // Call Appointment API and get appointment list

       // Call Medical Record API and get medical record list

       // Call Message API and get unread message list

       // Aggregate the responses 

       // Send response to the client.
      
   }

   // This API may have more resources for other functionalities
}

```

In the sample scenario, the desktop BFF(desktop_bff_service) is a shim used to support desktop application user experience. When a user loads the desktop application home page, there can be multiple calls to the desktop_bff_service to retrieve comparatively large amounts of data based on the desktop application requirement.  The desktop application can call desktop BFF separately to retrieve appointments and medical records. The desktop application can also call desktop BFF to retrieve messages and notifications in a single call. 

##### Skeleton code for desktop_bff_service.bal
```ballerina

import ballerina/http;

endpoint http:Listener listener {
   port: 9091
};

// Client endpoint to communicate with appointment management service
endpoint http:Client appointmentEP {
   url: "http://localhost:9092/appointment-mgt"
};

// Client endpoint to communicate with medical record service
endpoint http:Client medicalRecordEP {
   url: "http://localhost:9093/medical-records"
};

// Client endpoint to communicate with notification management service
endpoint http:Client notificationEP {
   url: "http://localhost:9094/notification-mgt"
};

// Client endpoint to communicate with message management service
endpoint http:Client messageEP {
   url: "http://localhost:9095/message-mgt"
};


// RESTful service.
@http:ServiceConfig { basePath: "/desktop-bff" }
service<http:Service> desktop_bff_service bind listener {

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/alerts"
   }
   getAlerts(endpoint client, http:Request req) {

       // This will return all message and notifications

       // Call Notification API and get notification list

       // Call Message API and get full message list

       // Generate the response from notification and message aggregation 

       // Send response to the client.  
    }

   @http:ResourceConfig {
       methods: ["GET"],
       path: "/appointments"
   }
   getAppoinments(endpoint client, http:Request req) {
       // Call Appointment API and get appointment list

       // Generate the response
      
       // Send response to the client.
           
   }
   @http:ResourceConfig {
       methods: ["GET"],
       path: "/medical-records"
   }
   getMedicalRecords(endpoint client, http:Request req) {

       // Call Medical Record API and get medical record list
    
       // Generate the response

       // Send response to the client.
   }

   // This API may have more resources for other functionalities
}

```

## Testing

### Invoking the service

Navigate to BFF/guide and execute the following commands via separate terminals to start all downstream services:
These commands will start appointment_mgt_service, medical_record_mgt_service, notification_mgt_service and message_mgt_service on ports 9092, 9093, 9094 and 9095 respectively. 

```bash
   $ ballerina run appointment_mgt 
```

```bash
   $ ballerina run medical_record_mgt
```

```bash
   $ ballerina run notification_mgt
```

```bash
   $ ballerina run message_mgt
```
The commands start appointment_mgt_service, medical_record_mgt_service, notification_mgt_service and message_mgt_service on ports 9092, 9093, 9094 and 9095 respectively. 

Similarly, execute the following commands via separate terminals to start the BFF layer services: 


```bash
   $ ballerina run mobile_bff 
```

```bash
   $ ballerina run desktop_bff
```
The commands start mobile_bff_service and desktop_bff_service on ports 9090 and 9091 respectively. 

For demonstration purpose let’s add sample data to the downstream services. Execute the following command to load sample appointments, medical records, notifications and messages to the services. 

```bash
   $ ballerina run sample_data_publisher
```

Now that you have sample data loaded to the downstream services, you can call the BFF layer to retrieve the data based on the requirement. 

The mobile application can call mobile BFF to retrieve the user profile using a single API call. 
Following is a sample curl command: 

```bash
   $ curl -v -X GET http://localhost:9090/mobile-bff/profile

   Output:

   < HTTP/1.1 200 OK
   < content-type: application/json
   < content-length: 900
   < server: ballerina/0.980.1
 
   {
   "Appointments":[{"ID":"APT01","Name":"Family Medicine","Location":"Main Hospital","Time":"2018-08-23, 08.30AM","Description":"Doctor visit for family medicine"},{"ID":"APT02","Name":"Lab Test Appointment","Location":"Main Lab","Time":"2018-08-20, 07.30AM","Description":"Blood test"}],
   "MedicalRecords":[{"ID":"MED01","Name":"Fasting Glucose Test","Description":"Test Result for Fasting Glucose test is normal"},{"ID":"MED02","Name":"Allergies","Description":"Allergy condition recorded due to Summer allergies"}],
   "Messages":[{"ID":"MSG02","From":"Dr. Sandra Robert","Subject":"Regarding flu season","Content":"Dear member, We highly recommend you to get the flu vaccination to prevent yourself from flu","Status":"Unread"},{"ID":"MSG03","From":"Dr. Peter Mayr","Subject":"Regarding upcoming blood test","Content":"Dear member, Your Glucose test is scheduled in early next month","Status":"Unread"}]
   }
  
```

The desktop application can call the desktop BFF to render the user profile using a few API calls. 

Following are curl commands that you can use to invoke the desktop BFF. 

```bash
   $ curl -v -X GET http://localhost:9091/desktop-bff/appointments

   Output:

   < HTTP/1.1 200 OK
   < content-type: application/json
   < content-length: 286
   < server: ballerina/0.980.1

   {"Appointments":[{"ID":"APT01","Name":"Family Medicine","Location":"Main Hospital","Time":"2018-08-23, 08.30AM","Description":"Doctor visit for family medicine"},{"ID":"APT02","Name":"Lab Test Appointment","Location":"Main Lab","Time":"2018-08-20, 07.30AM","Description":"Blood test"}]}

```

```bash
   $ curl -v -X GET http://localhost:9091/desktop-bff/medical-records

   Output:

   < HTTP/1.1 200 OK
   < content-type: application/json
   < content-length: 229
   < server: ballerina/0.980.1

   {"MedicalRecords":[{"ID":"MED01","Name":"Fasting Glucose Test","Description":"Test Result for Fasting Glucose test is normal"},{"ID":"MED02","Name":"Allergies","Description":"Allergy condition recorded due to Summer allergies"}]}

```

```bash
   $ curl -v -X GET http://localhost:9091/desktop-bff/alerts

   Output:
   
   < HTTP/1.1 200 OK
   < content-type: application/json
   < content-length: 761
   < server: ballerina/0.980.1

   {
   "Notifications":[{"ID":"NOT01","Name":"Lab Test Result Notification","Description":"Test Result of Glucose test is ready"},{"ID":"NOT02","Name":"Flu Vaccine Status","Description":"Flu vaccines due for this year"}],
   "Messages":[{"ID":"MSG01","From":"Dr. Caroline Caroline","Subject":"Regarding Glucose test result","Content":"Dear member, your test result remain normal","Status":"Read"},{"ID":"MSG02","From":"Dr. Sandra Robert","Subject":"Regarding flu season","Content":"Dear member, We highly recommend you to get the flu vaccination to prevent yourself from flu","Status":"Unread"},{"ID":"MSG03","From":"Dr. Peter Mayr","Subject":"Regarding upcoming blood test","Content":"Dear member, Your Glucose test is scheduled in early next month","Status":"Unread"}]
   }

```

### Writing unit tests

In Ballerina, unit test cases should be in the same package inside a directory named `tests`.  When writing test functions, follow the below convention:

- Annotate test functions with `@test:Config`. See the following example:

```ballerina
   @test:Config
   function testResourceGetUserProfile() {
```

> **NOTE**: The source code of this guide contains unit test cases for each resource available in the BFF services implemented above.

To run the unit tests, open your terminal and navigate to `backend-for-frontend/guide`, and then run the following command:
```bash
   $ ballerina test
```

> You can find the source code for the tests at [mobile_bff_service_test.bal](guide/mobile_bff/tests/mobile_bff_service_test.bal) and [desktop_bff_service_test.bal](guide/desktop_bff/tests/desktop_bff_service_test.bal).


## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

### Deploying locally

- To deploy locally, navigate to `backend-for-frontend/guide`, and execute the following command:

```bash
   $ ballerina build <Package_Name>
```
This builds a Ballerina executable archive (.balx) of the services that you developed. 

- Once the .balx files are created inside the target folder, you can use the following command to run the .balx files:

```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- Successful execution of a service displays an output similar to the following:
```bash
   ballerina: initiating service(s) in 'target/<Exec_Archive_File_Name>'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container.

The Ballerina language includes a [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Let’s deploy the four downstream services to Docker. 

 - In your downstream services(appointment_mgt_service, medical_record_mgt_service, notification_mgt_service, and message_mgt_service), you need to import ballerinax/docker and use the annotation @docker:Config as shown below to enable Docker image generation during build time. 

Let’s use the appointment_mgt_service as an example here. You need to follow the same steps for all four services. 

##### Skeleton code for appointment_mgt_service.bal
```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"appointment_mgt_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
    port: 9092
};

map<json> appointmentMap;


// RESTful service.
@http:ServiceConfig { basePath: "/appointment-mgt" }
service<http:Service> appointment_mgt_service bind listener {
....
```

Now navigate to the backend-for-frontend/guide, and execute the following command to build a Ballerina executable archive (.balx) of the services that you developed:
> **NOTE**: This also creates the corresponding Docker image using the Docker annotations that you have configured.

```
   $ballerina build appointment_mgt

   Output:

   Generating executable
    ./target/appointment_mgt.balx
@docker - complete 3/3 

Execute the following command to start the Docker container:
docker run -d -p 9092:9092 ballerina.guides.io/appointment_mgt_service:v1.0
```

- Once you successfully build the Docker images, you can execute the `` docker run`` command to run the services on Docker. Here you need to run the Docker images with the `` -p <host_port>:<container_port>`` argument to map the host port with the container port so that you can access the services through the host port. 
You should also use the ``–name`` argument to define the container name that will later allow BFF Docker containers to communicate with downstream services. 

Following are the sample commands to start all services on Docker:


```bash
   $ docker run -d -p 9092:9092 --name appointment-mgt-container ballerina.guides.io/appointment_mgt_service:v1.0
```
```bash
   $ docker run -d -p 9093:9093 --name medical-record-mgt-container ballerina.guides.io/medical_record_mgt_service:v1.0
```
```bash
   $ docker run -d -p 9094:9094 --name notification-mgt-container ballerina.guides.io/notification_mgt_service:v1.0
```
```bash
   $ docker run -d -p 9095:9095 --name message-mgt-container ballerina.guides.io/message_mgt_service:v1.0
```


Let's see how we can deploy the mobile_bff_service and desktop_bff_service we developed above on Docker. When invoking this service make sure that the other four services (appointment_mgt_service, medical_record_mgt_service, notification_mgt_service, and message_mgt_service) are also up and running in Docker. Also we have to change the endpoint URLs as per the Docker container names which is given when starting downstream services in previous step. 


- In our mobile_bff_service and desktop_bff_service, we need to import ballerinax/docker and use the annotation @docker:Config as shown below to enable Docker image generation during the build time.

##### Skeleton code for mobile_bff_service.bal
```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Config {
   registry:"ballerina.guides.io",
   name:"mobile_bff_service",
   tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
   port: 9090
};

// Client endpoint to communicate with appointment management service
endpoint http:Client appointmentEP {
    url: "http://appointment-mgt-container:9092/appointment-mgt"
};

// Client endpoint to communicate with medical record service
endpoint http:Client medicalRecordEP {
    url: "http://medical-record-mgt-container:9093/medical-records"
};

// Client endpoint to communicate with message management service
endpoint http:Client messageEP {
    url: "http://message-mgt-container:9095/message-mgt"
};

// RESTful service.
@http:ServiceConfig { basePath: "/mobile-bff" }
service<http:Service> mobile_bff_service bind listener {
....
```

##### Skeleton code for desktop_bff_service.bal
```ballerina
import ballerina/http;
import ballerinax/docker;


@docker:Config {
    registry:"ballerina.guides.io",
    name:"desktop_bff_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
    port: 9091
};

// Client endpoint to communicate with appointment management service
endpoint http:Client appointmentEP {
    url: "http://appointment-mgt-container:9092/appointment-mgt"
};

// Client endpoint to communicate with medical record service
endpoint http:Client medicalRecordEP {
    url: "http://medical-record-mgt-container:9093/medical-records"
};

// Client endpoint to communicate with notification management service
endpoint http:Client notificationEP {
    url: "http://notification-mgt-container:9094/notification-mgt"
};

// Client endpoint to communicate with message management service
endpoint http:Client messageEP {
    url: "http://message-mgt-container:9095/message-mgt"
};

// RESTful service.
@http:ServiceConfig { basePath: "/desktop-bff" }
service<http:Service> desktop_bff_service bind listener {
....
```


- Now you can build Ballerina executable archives (.balx) of the services that we developed above, using following commands. This will also create the corresponding Docker images using the Docker annotations that you have configured above. Navigate to backend-for-frontend/guide and run the following command.

```
   $ballerina build mobile_bff

   Output: 
   
   Generating executable
    ./target/mobile_bff.balx
@docker - complete 3/3 

Run following command to start docker container:
docker run -d -p 9090:9090 ballerina.guides.io/mobile_bff_service:v1.0
```

```
   $ballerina build desktop_bff

   Output:
   
   Generating executable
    ./target/desktop_bff.balx
        @docker                  - complete 3/3

        Run following command to start docker container:
        docker run -d -p 9091:9091 ballerina.guides.io/desktop_bff_service:v1.0
```


- Once you successfully build the Docker images, you can run them with the `` docker run`` command that is shown in the previous step output section. Here we run the Docker images with flag`` -p <host_port>:<container_port>``. So that we use the host port 9090 and the container port 9090 for mobile_bff_service and we use the host port 9091 and the container port 9091 for desktop_bff_service. Therefore you can access the services through the host port. Also you can link these BFF services to previously deployed downstream services by adding ``--link``  option so that the BFF services can communicate to downstream services. 

```bash
   $ docker run -d -p 9090:9090 --name mobile-bff-container --link appointment-mgt-container --link medical-record-mgt-container  --link message-mgt-container ballerina.guides.io/mobile_bff_service:v1.0
```

```bash
   $ docker run -d -p 9091:9091 --name desktop-bff-container --link appointment-mgt-container --link medical-record-mgt-container  --link notification-mgt-container --link message-mgt-container ballerina.guides.io/desktop_bff_service:v1.0
```


- Execute the `$ docker ps` command to verify whether the Docker container is running. The status of the Docker container should be shown as 'Up'.

```bash
   $ docker ps

   Output: 

   CONTAINER ID        IMAGE                                                 COMMAND                  CREATED              STATUS              PORTS                    NAMES
   4f85a06c1556        ballerina.guides.io/desktop_bff_service:v1.0          "/bin/sh -c 'balleri…"   3 seconds ago        Up 2 seconds        0.0.0.0:9091->9091/tcp   desktop-bff-container
   4e309c368da9        ballerina.guides.io/mobile_bff_service:v1.0           "/bin/sh -c 'balleri…"   About a minute ago   Up About a minute   0.0.0.0:9090->9090/tcp   mobile-bff-container
   6c531a26073b        ballerina.guides.io/message_mgt_service:v1.0          "/bin/sh -c 'balleri…"   4 minutes ago        Up 4 minutes        0.0.0.0:9095->9095/tcp   message-mgt-container
   a59928647216        ballerina.guides.io/notification_mgt_service:v1.0     "/bin/sh -c 'balleri…"   4 minutes ago        Up 4 minutes        0.0.0.0:9094->9094/tcp   notification-mgt-container
   afc7548a1548        ballerina.guides.io/medical_record_mgt_service:v1.0   "/bin/sh -c 'balleri…"   4 minutes ago        Up 4 minutes        0.0.0.0:9093->9093/tcp   medical-record-mgt-container
   0df660f601a2        ballerina.guides.io/appointment_mgt_service:v1.0      "/bin/sh -c 'balleri…"   4 minutes ago        Up 4 minutes        0.0.0.0:9092->9092/tcp   appointment-mgt-container

```

- Now you can publish some data to downstream services so that you consume from the BFF layer.  

```bash
   $ ballerina run sample_data_publisher
```

- You can access the service using the same curl commands that you used above.

```bash
   $ curl -v -X GET http://localhost:9090/mobile-bff/profile

   $ curl -v -X GET http://localhost:9091/desktop-bff/appointments

   $ curl -v -X GET http://localhost:9091/desktop-bff/medical-records

   $ curl -v -X GET http://localhost:9091/desktop-bff/alerts
```

### Deploying on Kubernetes

- If necessary, you can run the developed service on Kubernetes. The Ballerina language offers native support to run Ballerina programs on Kubernetes. 
To run a Ballerina program on Kubernetes, you need to add the relevant Kubernetes annotations to your 
service code. 
> **NOTE**: You do not need to explicitly create Docker images prior to deploying a service on Kubernetes. See [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

Let’s take a look at how to deploy the BFF services on Kubernetes. When you invoke this service make sure that the other four services (appointment_mgt_service, medical_record_mgt_service, notification_mgt_service, and message_mgt_service) are also up and running.

- First you need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable kubernetes deployment for the services you developed above.

> **NOTE**: You can use Minikube to try this out locally.

##### Skeleton code for mobile_bff_service.bal
```ballerina
import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
  hostname:"ballerina.guides.io",
  name:"ballerina-guides-mobile-bff-service",
  path:"/"
}

@kubernetes:Service {
  serviceType:"NodePort",
  name:"ballerina-guides-mobile-bff-service"
}

@kubernetes:Deployment {
  image:"ballerina.guides.io/mobile_bff_service:v1.0",
  name:"ballerina-guides-mobile-bff-service"
}

endpoint http:Listener listener {
   port: 9090
};

// http:Client endpoint definitions to communicate with other services

// RESTful service.
@http:ServiceConfig { basePath: "/mobile-bff" }
service<http:Service> mobile_bff_service bind listener {
....
```

##### Skeleton code for desktop_bff_service.bal
```ballerina
import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
  hostname:"ballerina.guides.io",
  name:"ballerina-guides-desktop-bff-service",
  path:"/"
}

@kubernetes:Service {
  serviceType:"NodePort",
  name:"ballerina-guides-desktop-bff-service"
}

@kubernetes:Deployment {
  image:"ballerina.guides.io/desktop_bff_service:v1.0",
  name:"ballerina-guides-desktop-bff-service"
}

endpoint http:Listener listener {
    port: 9091
};

// http:Client endpoint definitions to communicate with other services

// RESTful service.
// RESTful service.
@http:ServiceConfig { basePath: "/desktop-bff" }
service<http:Service> desktop_bff_service bind listener {
....
```

- Here you use ``  @kubernetes:Deployment `` to specify the Docker image name that will be created as part of building the service. 
- You need to specify `` @kubernetes:Service `` so that it can create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- You need to use `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

If you are using Minikube, you need to set a few additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). 
> **NOTE**:  If you want to obtain the IP address of the cluster, execute the `minikube ip` command.

- Now you can use the following command to build a Ballerina executable archive (.balx) of the service that you developed: 
> **NOTE**: This also creates the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured.

```
   $ ballerina build mobile_bff

   Output: 
     Run following command to deploy kubernetes artifacts: 
     kubectl apply -f ./target/kubernetes/mobile_bff
```

```
   $ ballerina build desktop_bff

   Output:
     Run following command to deploy kubernetes artifacts:
     kubectl apply -f ./target/kubernetes/desktop_bff
```

- Use the Docker images command to verify whether the Docker image that you specified in `@kubernetes:Deployment` is created.
- The Kubernetes artifacts related to the service should be generated in the`` ./target/kubernetes`` directory.
- Now you can execute the following command to create the Kubernetes deployment:

```bash
   $ kubectl apply -f ./target/kubernetes/mobile_bff

   Output: 

   deployment.extensions "ballerina-guides-mobile-bff-service" configured
   ingress.extensions "ballerina-guides-mobile-bff-service" configured
   service "ballerina-guides-mobile-bff-service" configured
```

```bash
   $ kubectl apply -f ./target/kubernetes/desktop_bff

   Output: 

   deployment.extensions "ballerina-guides-desktop-bff-service" configured
   ingress.extensions "ballerina-guides-desktop-bff-service" configured
   service "ballerina-guides-desktop-bff-service" configured
```

- You can use the following commands to verify whether the Kubernetes deployment, service, and ingress are running properly:

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If all artifacts are successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
```bash
   $ curl -v -X GET http://localhost:<Node_Port>/mobile-bff/profile
```
```bash
   $ curl -v -X GET http://localhost:<Node_Port>/desktop-bff/alerts
```

If you are using Minikube, you should use the IP address of the Minikube cluster obtained by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.

Ingress:

Add `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
```
   127.0.0.1 ballerina.guides.io
```

Access the service
```bash
   $ curl -v -X GET http://ballerina.guides.io/mobile-bff/profile
```

```bash
   $ curl -v -X GET http://ballerina.guides.io/desktop-bff/alerts
```

## Observability
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file and starting the Ballerina service using it. A sample configuration file can be found in `backend-for-frontend/guide/mobile_bff/`.

Ballerina is observable by default. This means that you can easily observe your services and resources using Ballerina. For more information, see [how-to-observe-ballerina-code](https://ballerina.io/learn/how-to-observe-ballerina-code/).
> **NOTE**: Observability is disabled by default via configuration in Ballerina. 
However, observability is disabled by default via configuration. 
To enable observability, add the following configurations to the `ballerina.conf` file, and start the Ballerina service using it. You can find a sample configuration file in `backend-for-frontend/guide/mobile_bff/`.


```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

To start the ballerina services using the configuration file, execute the following command:

```
   $ ballerina run --config mobile_bff/ballerina.conf mobile_bff
```
```
   $ ballerina run --config desktop_bff/ballerina.conf desktop_bff
```
> **NOTE**: The above configuration is the minimum configuration required to enable tracing and metrics. With these configurations, the default values load as configuration parameters of metrics and tracing.


### Tracing

You can monitor Ballerina services using the built-in tracing capabilities of Ballerina. You can use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.

Follow the steps below to use tracing with Ballerina.

- Add the following configurations for tracing: 
> **NOTE**: The following configurations are optional if you already have the basic configuration in the `ballerina.conf` file as described in the [Observability](#observability) section.

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

- Execute the following command to run the Jaeger Docker image:

```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 \
     -p16686:16686 -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `backend-for-frontend/guide` and execute the following command to run `mobile_bff_service` and `desktop_bff_service`:
```
   $ ballerina run --config mobile_bff/ballerina.conf mobile_bff
```
```
   $ ballerina run --config desktop_bff/ballerina.conf desktop_bff
```

- Use the Jaeger UI via the following URL to observe tracing:
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with Ballerina. You can use Prometheus as the monitoring tool.
Follow the steps below to set up Prometheus and view metrics for BFF service.

- You can add the following configurations for metrics. 
 > **NOTE**: The following configurations are optional if you already have the basic configuration in the `ballerina.conf` file as described in the [Observability](#observability) section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
```

- Create a file named `prometheus.yml` inside the `/tmp/` directory, and add the following configurations to the `prometheus.yml` file:
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

> **NOTE** : Be sure to replace `172.17.0.1` if your local Docker IP is different from `172.17.0.1`

- Execute the following command to run the Prometheus Docker image:

```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `backend-for-frontend/guide` and run the `mobile_bff_service` and `desktop_bff_service` using following commands.
```
  $ ballerina run --config mobile_bff/ballerina.conf mobile_bff
```
```
  $ ballerina run --config desktop_bff/ballerina.conf desktop_bff
```


- You can access Prometheus via the following URL:
```
   http://localhost:19090/
```

> **NOTE**: Ballerina has the following metrics by default for the HTTP server connector. You can enter the following expression in the Prometheus UI:
-  http_requests_total
-  http_response_time



### Logging

The Ballerina log package provides various functions that you can use to print log messages on the console, depending on your requirement. You can import the ballerina/log package and start logging. The following section describes how to search, analyze, and visualise logs in real time using Elastic Stack.

- Navigate to `backend-for-frontend/guide` and execute the following command to start the Ballerina service:
```
   $ nohup ballerina run mobile_bff > ballerina.log &
```
   > **NOTE**: This writes console logs to the `ballerina.log` file in the `backend-for-frontend/guide` directory.

- Execute the following command to start Elasticsearch:

```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2
```

  > **NOTE**: Linux users may need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count`
  
- Execute the following command to start the Kibana plugin for data visualisation with Elasticsearch:
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2    
```

- Follow the steps below to configure logstash to format Ballerina logs:

1. Create a file named `logstash.conf` with the following content:
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

2. Save the `logstash.conf` file inside a directory named `{SAMPLE_ROOT}\pipeline`

3. Execute the following command to start the logstash container:
> **NOTE**: Be sure to replace {SAMPLE_ROOT} with your directory name.
    
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
 
 - Follow the steps below to configure filebeat to ship Ballerina logs:

1. Create a file named `filebeat.yml` with the following content:

```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"] 
```
> **NOTE**: You can use the `$chmod go-w filebeat.yml` command to modify the ownership of the `filebeat.yml` file. 


2. Save the `filebeat.yml` file inside a directory named `{SAMPLE_ROOT}\filebeat`.

3. Execute the following command to start the logstash container.
> **NOTE**: Be sure to replace {SAMPLE_ROOT} with your directory name.

```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/travel_agency/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```

 - Execute the following URL to access Kibana and visualize logs:
```
   http://localhost:5601
```
