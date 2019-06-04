# Message broadcasting using topics

This guide is about broadcasting a message to several individual services in an asynchronous manner. In this example, the messages are published to a `Topic` in a message broker and there are services subscribed to that topic. Same copy of the message is received by each service and processed individually by each service. The message in fact is broadcasted to the services. 


The high level sections of this guide are as follows:

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Deployment](#deployment)
- [Testing](#testing)

## What you'll build
Let's consider a real world scenario where customers use a doctor channeling service. It facilitates channeling doctors at different hospitals registered in the system. The appointment request is processed by the system and the details are stored in two ways. 

1. In a database - will be used by hospital staff to query the appointments made
2. In a CSV file - will be used by an analytic software system to generate statistics 



Here, the user's doctor appointment request is sent to the `healthcare service`. It makes the appointment and responds with a Json message with appointment details. This message is forwarded to topic called `appointments` created in ActiveMQ broker. If message is forwarded without an issue, user will get successful message acceptance as the response. The service `database_writer` subscribed to the `appointment` topic, will get the appointment details, extract out important data and store the record in `appointments` database in `MySQL`. The service `file_writer` subscribed to the `appointment` topic, will get the same message and add a record to the CSV file called `appointments`. 

> For simplicity, we will omit the requirement of retrying to store the message incase of a failure (i.e temporary DB failure). Note in this example the two operations of storing the record in DB and storing it in the CSV file are completely independent and they are not aware of each other.  

This scenario will cover the following elements of integration 

1. How to receive an HTTP message and invoke an HTTP backend service
2. How to send a message to a Topic created in a JMS broker
3. How to receive a message from a Topic created in a JMS broker
4. How to convert a text message into a Json message
5. How to do a database insert with information extracted from a Json 
6. How to write a CSV file

The following diagram illustrates the scenario:

![alt text](resources/message_broadcasting.svg)



## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After you install ActiveMQ, copy the .jar files from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
   * If you use ActiveMQ version 5.12.0, you only have to copy `activemq-client-5.12.0.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar`, and `hawtbuf-1.11.jar` from the `<AMQ_HOME>/lib` directory to the `<BALLERINA_HOME>/bre/lib` directory.
- [MySQL](https://www.mysql.com/downloads/) 
  * After you install MySQL, copy the MySQL connector jar file (download the relevant version from [here](https://dev.mysql.com/downloads/connector/j/)) to
    to the `<BALLERINA_HOME>/bre/lib` directory.

## Implementation

TODO: best practices

> If you want to skip the basics and move directly to the [Testing](#testing) section, you can download the project from git and skip the [Implementation](#implementation) instructions.

### Setting up MySQL

* After you install MySQL, source the `database_script` below using MySQL client or `MySQL Workbench` tool. This will create the necessary database, table and set privileges. SQL file can be found at resources/database_script.sql.  

``` sql
CREATE DATABASE IF NOT EXISTS healthcare;
USE healthcare;
CREATE TABLE IF NOT EXISTS APPOINTMENTS (
    AppointmentNumber INT,
    AppointmentDate VARCHAR(200),
    Fee INT,
    Doctor VARCHAR(200),
    Hospital  VARCHAR(200),
    Patient VARCHAR(200),
    Phone VARCHAR(200)
);

CREATE USER wso2@'%' IDENTIFIED BY 'wso2'; 
GRANT ALL PRIVILEGES ON *.* TO 'wso2'@'%';
FLUSH PRIVILEGES;
```

### Creating the project structure
Ballerina is a complete programming language that supports custom project structures. 

To implement the scenario in this guide, you can use the following package structure:

```
message-broadcasting
    ├── guide
        ├── database_writer.bal
        ├── file_writer.bal
        └── http_message_receiver.bal
```
     
- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to , and run the Ballerina project initializing toolkit.

```ballerina
   $ ballerina init
```
Now that you have created the project structure, the next step is to develop the service.

### Developing the service

1. First you need to implement `http_message_receiver.bal` which will listen for HTTP messages over port 9091 and forward it to `healthcare` service. The response from the service is then sent to `appointments` topic of ActiveMQ broker. 
2. Then you need to implement `database_writer.bal` which will listen on the same ActiveMQ topic, receive JMS message, convert it back to a Json message, extract required data and insert the appointment record to `appointments` table we created.   
3. Finally, you need to implement `file_writer.bal` which will listen on the same ActiveMQ topic, receive JMS message, convert it back to a Json message, extract required data and insert the record to a CSV file. Upon every message received, a new record is added to the CSV file. 

Take a look at the code samples below to understand how to implement each service. 

**http_message_receiver.bal**
```ballerina
import ballerina/log;
import ballerina/http;
import ballerina/jms;
import ballerina/io;

//init the HTTP client for appointment service
http:Client appointmentClient = new("http://localhost:9090");

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a topic publisher using the created session
jms:TopicPublisher topicPublisher = new(jmsSession, topicPattern = "appointmentTopic");

//export http listner port on 9091
listener http:Listener httpListener = new(9091);

// Healthcare Service, which allows users to channel doctors online
@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcareService on httpListener {
    // Resource that allows users to make appointments
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function make_appointment(http:Caller caller, http:Request request) returns error? {
        http:Response clientResponse = new;
        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            json responseMessage;
            //invoke HTTP service to make the appointment
            var response = appointmentClient->post("/grandoaks/categories/surgery/reserve ", untaint payload);
            if (response is http:Response) {
                var resPayload = response.getJsonPayload();
                if (resPayload is json) {
                    log:printInfo("Response is : " + resPayload.toString());
                    //Send the message to the Topic
                    var topicMessage = jmsSession.createTextMessage(resPayload.toString());
                    if (topicMessage is jms:Message) {
                        check topicPublisher->send(topicMessage);
                        // Construct a success message for the response
                        responseMessage = {                             "Message": "Your appointment is successfully placed"};
                        log:printInfo("New appointment added to the JMS topic; Patient: " + payload.patient.name.toString());
                    } else {
                        log:printError("Error occured while adding appointment to the JMS topic");
                        responseMessage = {                             "Message": "Internal error occured while storing the appointment"};
                        clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                    }
                } else {
                    log:printError("Error parsing response from appointment service " + <string> resPayload.detail().message);
                    clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                    responseMessage = {                         "Message": "Internal error occured while storing the appointment"};
                }
            } else {
                log:printError("Error when invoking appointment service " + <string> response.detail().message);
                clientResponse.statusCode = http:INTERNAL_SERVER_ERROR_500;
                responseMessage = {                     "Message": "Internal error occured when invoking appointment service"};
            }
            // Send response to the user
            clientResponse.setJsonPayload(responseMessage);
            check caller->respond(clientResponse);
        } else {
            clientResponse.statusCode = 400;
            clientResponse.setJsonPayload({
                "Message": "Invalid payload - Not a valid JSON payload"
            });
            check caller->respond(clientResponse);
            return;
        }

    }
}
```


**database_writer.bal**
```ballerina
import ballerina/jms;
import ballerina/log;
import ballerina/http;
import ballerina/io;
import ballerina/mysql;
import ballerina/sql;

//JMS listener listening on topic
listener jms:TopicSubscriber subscriberEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, topicPattern = "appointmentTopic");

//MySQL DB client configuration
mysql:Client healthcareDB = new({
        host: "localhost",
        port: 3306,
        name: "healthcare",
        username: "wso2",
        password: "wso2",
        dbOptions: { useSSL: false }
    });

service jmsListener on subscriberEndpoint {
    //invoked upon JMS message receive
    resource function onMessage(jms:TopicSubscriberCaller consumer,
    jms:Message message) {
        //receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json jasonMessage = checkpanic sr.readJson();
            //write to database
            writeToDB(jasonMessage);

        } else {
            log:printInfo("Error occurred while reading message " + messageText.reason());
        }
    }
}

function writeToDB(json payload) {
    log:printInfo("Adding appointment details to the database: " + payload.toString());

    //{"appointmentNumber":4, "doctor":{"name":"thomas collins", "hospital":"grand oak community hospital",
    //"category":"surgery", "availability":"9.00 a.m - 11.00 a.m", "fee":7000.0}, "patient":{"name":"John Doe",
    // "dob":"1940-03-19", "ssn":"234-23-525", "address":"California", "phone":"8770586755", "email":"johndoe@gmail.com"},
    // "fee":7000.0, "confirmed":false, "appointmentDate":"2025-04-02"}
    int appointmentNumber = <int> payload.appointmentNumber;
    string appointmentDate = <string> payload.appointmentDate;
    int fee = <int> payload.fee;
    string doctor = <string> payload.doctor.name;
    string hospital = <string> payload.doctor.hospital;
    string patient = <string> payload.patient.name;
    string phone = <string> payload.patient.phone;

    string sqlString = "INSERT INTO APPOINTMENTS (AppointmentNumber, 
        AppointmentDate, Fee, Doctor, Hospital, Patient, Phone) VALUES (?,?,?,?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var result = healthcareDB->update(sqlString, appointmentNumber, appointmentDate, fee, doctor, hospital, patient, phone);
    handleUpdate(result, "Insert to appointment table");
}

function handleUpdate(sql:UpdateResult | error returned, string message) {
    if (returned is sql:UpdateResult) {
        log:printInfo(message + " status: " + returned.updatedRowCount);
    } else {
        log:printInfo(message + " failed: " + <string>returned.detail().message);
    }
}

```

**file_writer.bal**
```ballerina
import ballerina/jms;
import ballerina/log;
import ballerina/mysql;
import ballerina/sql;
import ballerina/io;

//file channel for the CSV file
string filePath = "../resources/appointments.csv";
io:WritableCSVChannel csvch = prepareCSV(filePath);

//JMS lister listening on topic
listener jms:TopicSubscriber subscriberEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, topicPattern = "appointmentTopic");

service jmsListener on subscriberEndpoint {


    //invoked upon JMS message receive
    resource function onMessage(jms:TopicSubscriberCaller consumer,
    jms:Message message) {
        //receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json jasonMessage = checkpanic sr.readJson();
            //write to file
            var result = writeCsv(jasonMessage);
            if (result is error) {
                log:printError("Error occurred while writing csv record :", err = result);
            } else {
                log:printInfo("json record successfully transformed to a csv, file could" +
                " be found in " + filePath);
            }
        } else {
            log:printInfo("Error occurred while reading message " + messageText.reason());
        }
    }
}

function prepareCSV(string path) returns io:WritableCSVChannel {
    io:WritableCSVChannel temp = io:openWritableCsvFile(path);
    string[] headers = ["AppointmentNumber", "AppointmentDate", "Fee", "Doctor", "Hospital", "Patient", "Phone"];
    checkpanic temp.write(headers);
    return temp;
}

function writeCsv(json payload) returns error? {
    log:printInfo("Json to write : " + payload.toString());
    string appointmentNumber = string.convert(<int> payload.appointmentNumber);
    string appointmentDate = <string> payload.appointmentDate;
    string fee = string.convert(<float>payload.fee);
    string doctor = <string> payload.doctor.name;
    string hospital = <string> payload.doctor.hospital;
    string patient = <string> payload.patient.name;
    string phone = <string> payload.patient.phone;

    string[] data = [appointmentNumber, appointmentDate, fee, doctor, hospital, patient, phone];
    check csvch.write(data);
}

function getFields(json rec) returns (string[], string[]) {
    int count = 0;
    string[] headers = [];
    string[] fields = [];
    headers = rec.getKeys();
    foreach var field in headers {
        fields[count] = rec[field].toString();
        count = count + 1;
    }
    return (headers, fields);
}
```

## deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

To deploy locally, navigate to asynchronous-messaging/guide, and execute the following command.

```
$ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder. 
You can run them by 

```
$ ballerina run <Exec_Archive_File_Name>
```

### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container.The Ballerina language includes a Ballerina_Docker_Extension, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

Since ActiveMQ is a prerequisite in this guide, there are a few more steps you need to follow to run the service you developed in a Docker container. Please navigate to [ActiveMQ on Dockerhub](https://hub.docker.com/r/webcenter/activemq) and follow the instructions. 

MySQL is also a prerequisite in this guide. You can run MySQL on Docker as well. To run MySQL please navigate to [MySQL on Dockerhub](https://hub.docker.com/_/mysql) and follow the instructions.  


## Testing
Follow the steps below to invoke the service.

- On a new terminal, navigate to `<AMQ_HOME>/bin`, and execute the following command to start the ActiveMQ server.

```
   $ ./activemq start
```
- Make sure MySQL server is running and the database, tables are created in the instance following the section [Setting up MySQL](###Setting-up-MySQL) 
- Navigate to `message-broadcasting/guide`, and execute the following commands via separate terminals to start each service:
 
```ballerina
   $ ballerina run http_message_receiver.bal
   $ ballerina run database_writer.bal
   $ ballerina run file_writer.bal
```
- Create a file called input.json with following json request to simulate placing doctor appointments:

``` json
{
  "patient": {
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com"
  },
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital",
  "appointment_date": "2025-04-02"
}
```
- Send the message using curl 
```
curl -v -X POST --data @input.json http://localhost:9091/healthcare/make_appointment --header "Content-Type:application/json"
```
#### Output
 - You will see the following log, which confirms that the `http_message_receiver` service has sent the request to the ActiveMQ queue.

    ```
    New appointment added to the JMS topic; Patient: John Doe
    ```

 - At the `database_writer` service you will see following log as record is successfully added to the database.  

    ```
    Adding appointment details to the database: {"appointmentNumber":22, "doctor":{"name":"thomas collins", "hospital":"grand oak community hospital", "category":"surgery", "availability":"9.00 a.m - 11.00 a.m", "fee":7000.0}, "patient":{"name":"John Doe", "dob":"1940-03-19", "ssn":"234-23-525", "address":"California", "phone":"8770586755", "email":"johndoe@gmail.com"}, "fee":7000.0, "confirmed":false, "appointmentDate":"2025-04-02"}
    ```
- Query MySQL table to see if records are inserted

    ``` sql
    select * from APPOINTMENTS;
    ```

    | AppointmentNumber | AppointmentDate | Fee  | Doctor         | Hospital                     | Patient  | Phone      |
    |-------------------|-----------------|------|----------------|------------------------------|----------|------------|
    | 2                 | 2025-04-02      | 7000 | thomas collins | grand oak community hospital | John Doe | 8770586755 |
        

- Check if a CSV file is created under `message-broadcasting/resources/appointments.csv`

- Navigate to ActiveMQ console (http://localhost:8161/admin/topics.jsp). Number of enqueued and dequeued messages of the topic `appointments` should be `1`.


