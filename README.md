# Messaging with Kafka

Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records get published. Topics in Kafka are always multi-subscriber.

> This guide walks you through the process of messaging with Apache Kafka using Ballerina language. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build
To understand how you can use Kafka for publish-subscribe messaging, let's consider a real-world use case of a product management system. This product management system consists of a product admin portal using which the product administrator can update the price for a product. This price update message should be consumed by a couple of franchisees and an inventory control system to take appropriate actions. Kafka is an ideal messaging system for this scenario. In this particular use case, once the admin updates the price of a product, the update message is published to a Kafka topic called 'product-price' to which the franchisees and the inventory control system subscribed to listen. The following diagram illustrates this use case clearly.


![alt text](/images/messaging-with-kafka.svg)


In this example, the Ballerina Kafka Connector is used to connect Ballerina to Apache Kafka. With this Kafka Connector, Ballerina can act as both message publisher and subscriber.

## Prerequisites
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- [Apache Kafka 1.0.0](https://kafka.apache.org/downloads)
  * Download the binary distribution and extract the contents
- [Ballerina Kafka Connector](https://github.com/wso2-ballerina/package-kafka)
  * After downloading the ZIP file, extract it and copy the containing JAR files into the <BALLERINA_HOME>/bre/lib folder
- A Text Editor or an IDE 

**Optional requirements**
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service

### Before you begin
#### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
messaging-with-kafka
├── ProductMgtSystem
│   ├── Publisher
│   │   ├── product_admin_portal.bal
│   │   └── product_admin_portal_test.bal
│   └── Subscribers
│       ├── Franchisee1
│       │   └── franchisee1.bal
│       ├── Franchisee2
│       │   └── franchisee2.bal
│       └── InventoryControl
│           └── inventory_control_system.bal
└── README.md

```

Package `Publisher` contains the file that handles the Kafka message publishing and a unit test file. 

Package `Subscribers` contains three different subscribers who subscribed to Kafka topic 'product-price'.

You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `messaging-with-kafka` and navigate to that directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
$ballerina init -i

Create Ballerina.toml [yes/y, no/n]: (n)  
Ballerina source [service/s, main/m]: (s)
Package for the service : (no package) ProductMgtSystem.Publisher
Ballerina source [service/s, main/m, finish/f]: (f) s
Package for the service : (no package) ProductMgtSystem.Subscribers
Ballerina source [service/s, main/m, finish/f]: (f)

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change the names of the generated files to match with our guide project filenames.

### Implementation

Let's get started with the implementation of a Kafka service, which is subscribed to the Kafka topic 'product-price'. Let's consider `inventory_control_system.bal` for example. Let's first see how to add the Kafka configurations for a Kafka subscriber written in Ballerina language. Refer to the code segment attached below.

##### Kafka subscriber configurations
```ballerina
// Kafka subscriber configurations
@Description {value:"Service level annotation to provide Kafka consumer configuration"}
endpoint kafka:SimpleConsumer consumer {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "inventorySystemd",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval:1000
};
```

A Kafka subscriber in Ballerina should contain the `@kafka:configuration {}` block in which you specify the required configurations for a Kafka subscriber. 

The `bootstrapServers` field provides the list of host and port pairs, which are the addresses of the Kafka brokers in a "bootstrap" Kafka cluster. 

The `groupId` field specifies the Id of the consumer group. 

The `topics` field specifies the topics that must be listened by this consumer. 

The `pollingInterval` field is the time interval that a consumer polls the topic. 

Let's now see the complete implementation of the `inventory_control_system.bal` file, which is a Kafka topic subscriber.

##### inventory_control_system.bal
```ballerina
import ballerina/log;
import wso2/kafka;

// Kafka consumer endpoint
endpoint kafka:SimpleConsumer consumer {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "inventorySystemd",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval:1000
};

// Kafka service that listens from the topic 'product-price'
// 'inventoryControlService' subscribed to new product price updates from the product admin
// and updates the Database
service<kafka:Consumer> kafkaService bind consumer {
    // Triggered whenever a message added to the subscribed topic
    onMessage(kafka:ConsumerAction consumerAction, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service, We process each one by one.
        int counter = 0;
        while (counter < lengthof records) {
            blob serializedMsg = records[counter].value;
            // Convert the serialized message to string message
            string msg = serializedMsg.toString("UTF-8");
            log:printInfo("New message received from the product admin");
            // log the retrieved Kafka record
            log:printInfo("Topic: " + records[counter].topic + "; Received Message: " + msg);
            // Mock logic
            // Update the database with the new price for the specified product
            log:printInfo("Database updated with the new price for the specified product");
            counter = counter + 1;
        }
    }
}

```

In the above code, you have implemented a Kafka service that is subscribed to listen to the 'product-price' topic. You provided the Kafka subscriber configurations for this Kafka service as shown above. 

Resource `onMessage` is triggered whenever a message is published to the topic specified.

To check the implementations of the other subscribers, see the [franchisee1.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/ProductMgtSystem/Subscribers/Franchisee1/franchisee1.bal) file and the [franchisee2.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/ProductMgtSystem/Subscribers/Franchisee2/franchisee2.bal) file.

Let's next focus on the implementation of `product_admin_portal.bal`, which acts as the message publisher. It contains an HTTP service, using which, a product admin can update the price of a product. 

In this example, you first serialized the message in `blob` format before publishing it to the topic. Then `kafka:ProducerRecord` is created where you specify the serialized message, destination topic name, and the number of partitions. Then you specified the Kafka producer cofigurations by creating a `kafka:ProducerConfig`. Look at the code snippet added below.

##### Kafka producer configurations
```ballerina
endpoint kafka:SimpleProducer kafkaProducer {
    bootstrapServers: "localhost:9092",
    clientID:"basic-producer",
    acks:"all",
    noRetries:3
};
```

Let's now see the structure of the `product_admin_portal.bal` file. Inline comments are added for better understanding.

##### product_admin_portal.bal
```ballerina
import ballerina/http;
import wso2/kafka;
import ballerina/log;

// Constants to store admin credentials
@final
string ADMIN_USERNAME = "Admin";
@final
string ADMIN_PASSWORD = "Admin";

// Kafka ProducerClient endpoint
endpoint kafka:ProducerEndpoint kafkaProducer {
    bootstrapServers: "localhost:9092",
    clientID:"basic-producer",
    acks:"all",
    noRetries:3
};

// HTTP service endpoint
endpoint http:Listener serviceEP {
    port:9090
};

@http:ServiceConfig {
    endpoints:[serviceEP],
    basePath:"/product"
}
service<http:Service> productAdminService bind serviceEP {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/updatePrice",
        consumes:["application/json"],
        produces:["application/json"]
    }
    updatePrice (endpoint connection, http:Request request) {
        http:Response response = new;

        // Try getting the JSON payload from the incoming request
        json payload = check request.getJsonPayload();
        json username = payload.Username;
        json password = payload.Password;
        json productName = payload.Product;
        json newPrice = payload.Price;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (username == null || password == null || productName == null || newPrice == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request: Invalid payload"});
            _ = connection->respond(response);
        }

        float newPriceAmount;

        // Convert the price value to float
        var result = <float>newPrice.toString();
        match result {
            float value => {
                newPriceAmount = value;
            }

            error err => {
                response.statusCode = 400;
                json payload = {"Message":"Invalid amount specified for field 'Price'"};
                response.setJsonPayload(payload);
                connection->respond(response) but 
                          { error e => log:printError("Error in responding ", err = e) };
            }
        }

        // If the credentials does not match with the admin credentials, send an 
        // "Access Forbidden" response message
        if (username.toString() != ADMIN_USERNAME || password.toString() != ADMIN_PASSWORD) {
            response.statusCode = 403;
            response.setJsonPayload({"Message":"Access Forbidden"});
            connection->respond(response) but 
                   { error e => log:printError("Error in responding ", err = e) };
        }

        // Construct and serialize the message to be published to the Kafka topic
        json priceUpdateInfo = {"Product":productName, "UpdatedPrice":newPriceAmount};
        blob serializedMsg = priceUpdateInfo.toString().toBlob("UTF-8");
        // Create the Kafka ProducerRecord and specify the destination topic 
        // - 'product-price' in this case
        // Set a valid partition number, which will be used when sending the record
        kafkaProducer->send(serializedMsg, "product-price", partition = 0);

        // Send a success status to the admin request
        response.setJsonPayload({"Status":"Success"});
        connection->respond(response) but 
              { error e => log:printError("Error in responding ", err = e) };
    }
}
```

To see the complete implementation of the above, see the [product_admin_portal.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/ProductMgtSystem/Publisher/product_admin_portal.bal) file. 

## Testing 

### Try it out

- Start the `ZooKeeper` instance with default configurations by entering the following command in a terminal.

 ```bash
    <KAFKA_HOME_DIRECTORY>$ bin/zookeeper-server-start.sh config/zookeeper.properties
 ```

- Start a single `Kafka broker` instance with default configurations by entering the following command in a different terminal.

```bash
   <KAFKA_HOME_DIRECTORY>$ bin/kafka-server-start.sh config/server.properties
```
   Here we started the Kafka server on host:localhost, port:9092. Now we have a working Kafka cluster.

- Create a new topic `product-price` on Kafka cluster by entering the following command in a different terminal.

```bash
   <KAFKA_HOME_DIRECTORY>$ bin/kafka-topics.sh --create --topic product-price --zookeeper \
   localhost:2181 --replication-factor 1 --partitions 2
```
   Here we created a new topic that consists of two partitions with a single replication factor.
   
- Run the `productAdminService`, which is an HTTP service that publishes messages to the Kafka topic, and the Kafka services in the `Subscribers` package, which are subscribed to listen to the Kafka topic by entering the following commands in sperate terminals.

```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina run ProductMgtSystem/Publisher/
```

```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina run ProductMgtSystem/Subscribers/<Subscriber_Package_Name>/
```
   
- Invoke the `productAdminService` by sending a POST request to update the price of a product with Admin credentials.

```bash
   curl -v -X POST -d '{"Username":"Admin", "Password":"Admin", "Product":"ABC", "Price":100.00}' \
   "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
```

- The `productAdminService` sends a response similar to the following:
```bash
   < HTTP/1.1 200 OK
   {"Status":"Success"}
```

- Sample log messages in subscribed Kafka services:
```bash
     INFO  [<All>] - New message received from the product admin 
     INFO  [<All>] - Topic: product-price; Received Message {"Product":"ABC","UpdatedPrice":100.0} 
     INFO  [Franchisee1] - Acknowledgement from Franchisee 1 
     INFO  [Franchisee2] - Acknowledgement from Franchisee 2 
     INFO  [InventoryControl] - Database updated with the new price for the specified product
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
* Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
  function testProductAdminService () {
```
  
This guide contains unit test cases for each method available in the 'order_mgt_service' implemented above. 

To run the unit tests, navigate to the sample root directory and run the following command.
```bash
   $ballerina test ProductMgtSystem/Publisher/
```

To check the implementation of this test file, see the [product_admin_portal_test.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/ProductMgtSystem/Publisher/product_admin_portal_test.bal) file.

## Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below. 

### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and run them in your local environment as follows.

Building 
```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina build ProductMgtSystem/Publisher/

   <SAMPLE_ROOT_DIRECTORY>$ ballerina build ProductMgtSystem/Subscribers/<Subscriber_Package_Name>/
```

Running
```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina run <Exec_Archive_File_Name>
```
