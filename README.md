# Messaging with Kafka
This guide walks you through the process of messaging with Apache Kafka using Ballerina language. Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records published. Topics in Kafka are always multi-subscriber.

## <a name="what-you-build"></a>  What you’ll build
To understanding how you can use Kafka for publish-subscribe messaging, let's consider a real-world use case of a product management system. This product management system consists of a product admin portal using which the product administrator can update the price for a product. This price update message should be consumed by a couple of franchisees and an inventory control system to take appropriate actions. Kafka is an ideal messaging system for this scenario. In this particular use case, once the admin updates the price of a product, the update message is published to a Kafka topic called 'product-price' to which the franchisees and the inventory control system subscribed to listen. The below diagram illustrates this use case clearly.


![alt text](/images/Kafka.png)


In this example Ballerina Kafka Connector is used to connect Ballerina and Apache Kafka. With this Kafka Connector, Ballerina can act as both message publisher and subscriber.

## <a name="pre-req"></a> Prerequisites
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- [Apache Kafka 1.0.0](https://kafka.apache.org/downloads)
  * Download the binary distribution and extract the contents
- [Ballerina Kafka Connector](https://github.com/wso2-ballerina/package-kafka)
  * After downloading the zip file, extract it and copy the containing jars into <BALLERINA_HOME>/bre/lib folder
- A Text Editor or an IDE 

Optional Requirements
- Ballerina IDE plugins (IntelliJ IDEA, VSCode, Atom)

## <a name="developing-service"></a> Developing the service

### <a name="before-begin"></a> Before you begin
##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

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


### <a name="Implementation"></a> Implementation

Let's get started with the implementation of a Kafka service, which is subscribed to the Kafka topic 'product-price'. Let's consider `inventory_control_system.bal` for example. Refer the code attached below. Inline comments added for better understanding.

##### inventory_control_system.bal
```ballerina
package ProductMgtSystem.Subscribers.InventoryControl;

import ballerina.net.kafka;
import ballerina.log;

// Kafka subscriber configurations
@Description {value:"Service level annotation to provide Kafka consumer configuration"}
@kafka:configuration {
    bootstrapServers:"localhost:9092, localhost:9093",
    // Consumer group ID
    groupId:"inventorySystem",
    // Listen from topic 'product-price'
    topics:["product-price"],
    // Poll every 1 second
    pollingInterval:1000
}
// Kafka service that listens from the topic 'product-price'
// 'inventoryControlService' subscribed to new product price updates from the product admin and updates the Database
service<kafka> inventoryControlService {
    // Triggered whenever a message added to the subscribed topic
    resource onMessage (kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service and process each one by one
        int counter = 0;
        while (counter < lengthof records) {
            // Get the serialized message
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

In the above code, we have implemented a Kafka service that is subscribed to listen the topic 'product-price'. We require providing the Kafka subscriber configurations for this Kafka service. `@kafka:configuration {}` block contains these Kafka consumer configurations. Field `bootstrapServers` provides the list of host and port pairs, which are the addresses of the Kafka brokers in a "bootstrap" Kafka cluster. Field `groupId` specifies the Id of the consumer group. Field `topics` specifies the topics need to be listened by this consumer. Field `pollingInterval` is the time interval that a consumer polls the topic. 

Resource `onMessage` will be triggered whenever a message published to the topic specified.

To check the implementations of the other subscribers refer [franchisee1.bal](https://github.com/pranavan15/messaging-with-kafka/blob/master/ProductMgtSystem/Subscribers/Franchisee1/franchisee1.bal) and [franchisee2.bal](https://github.com/pranavan15/messaging-with-kafka/blob/master/ProductMgtSystem/Subscribers/Franchisee2/franchisee2.bal).


Let's next focus on the implementation of `product_admin_portal.bal`, which acts as the message publisher. It contains an HTTP service using which a product admin can update the price of a product. Skeleton of `product_admin_portal.bal` is attached below. Inline comments added for better understanding.

##### product_admin_portal.bal
```ballerina
package ProductMgtSystem.Publisher;

// imports

// Constants to store admin credentials
const string ADMIN_USERNAME = "Admin";
const string ADMIN_PASSWORD = "Admin";

// Product admin service
@http:configuration {basePath:"/product"}
service<http> productAdminService {
    // Resource that allows the admin to send a price update for a product
    @http:resourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    resource updatePrice (http:Connection connection, http:InRequest request) {
      
        // Try getting the JSON payload from the incoming request

        // Check whether the specified value for 'Price' is appropriate

        // Check whether the credentials provided are Admin credentials

        // Kafka message publishing logic
        // Construct and serialize the message to be published to the Kafka topic
        json priceUpdateInfo = {"Product":productName, "UpdatedPrice":newPrice};
        blob serializedMsg = priceUpdateInfo.toString().toBlob("UTF-8");
        // Create the Kafka ProducerRecord and specify the destination topic - 'product-price' in this case
        // Set a valid partition number, which will be used when sending the record
        kafka:ProducerRecord record = {value:serializedMsg, topic:"product-price", partition:0};

        // Create a Kafka ProducerConfig with optional parameters 'clientID' - for broker side logging,
        // acks - number of acknowledgments for requests, noRetries - number of retries if record send fails
        kafka:ProducerConfig producerConfig = {clientID:"basic-producer", acks:"all", noRetries:3};
        // Produce the message and publish it to the Kafka topic
        kafkaProduce(record, producerConfig);
        
        // Send a success status to the admin request
    }
}

// Function to produce and publish a given record to a Kafka topic
function kafkaProduce (kafka:ProducerRecord record, kafka:ProducerConfig producerConfig) {
    // Kafka ProducerClient endpoint
    endpoint<kafka:ProducerClient> kafkaEP {
        create kafka:ProducerClient(["localhost:9092, localhost:9093"], producerConfig);
    }
    // Publish the record to the specified topic
    kafkaEP.sendAdvanced(record);
    kafkaEP.flush();
    // Close the endpoint
    kafkaEP.close();
}

```

Refer [product_admin_portal.bal](https://github.com/pranavan15/messaging-with-kafka/blob/master/ProductMgtSystem/Publisher/product_admin_portal.bal) to see the complete implementation of the above.

## <a name="testing"></a> Testing 

### <a name="try-it"></a> Try it out

1. Start `ZooKeeper` instance with default configurations by entering the following command in a terminal

   ```bash
   <KAFKA_HOME_DIRECTORY>$ bin/zookeeper-server-start.sh config/zookeeper.properties
   ```

2. Start single `Kafka broker` instance with default configurations by entering the following command in a different terminal

   ```bash
   <KAFKA_HOME_DIRECTORY>$ bin/kafka-server-start.sh config/server.properties
   ```
   Here we started the Kafka server on host:localhost, port:9092. Now we have a working Kafka cluster.

3. Create a new topic `product-price` on Kafka cluster by entering the following command in a different terminal 

   ```bash
   <KAFKA_HOME_DIRECTORY>$ bin/kafka-topics.sh --create --topic product-price --zookeeper localhost:2181 --replication-factor 1 --partitions 2
   ```
   Here we created a new topic consists of two partitions with a single replication factor.
   
4. Run both the HTTP service `productAdminService`, which publishes messages to the Kafka topic, and Kafka services in `Subscribers` package, which subscribed to listen the Kafka topic by entering the following commands in sperate terminals

   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run ProductMgtSystem/Publisher/
   ```

   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run ProductMgtSystem/Subscribers/<Subscriber_Package_Name>/
   ```
   
5.  Invoke the `productAdminService` by sending a POST request to update the price of a product with Admin credentials

    ```bash
    curl -v -X POST -d '{"Username":"Admin", "Password":"Admin", "Product":"ABC", "Price":100.00}' \
     "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
    ```

    The `productAdminService` should respond something similar,
    ```bash
     < HTTP/1.1 200 OK
    {"Status":"Success"}
    ```

    Sample Log Messages in subscribed Kafka services
    ```bash
     INFO  [ProductMgtSystem.Subscribers.<All>] - New message received from the product admin 
     INFO  [ProductMgtSystem.Subscribers.<All>] - Topic: product-price; Received Message {"Product":"ABC","UpdatedPrice":100.0} 
     INFO  [ProductMgtSystem.Subscribers.Franchisee1] - Acknowledgement from Franchisee 1 
     INFO  [ProductMgtSystem.Subscribers.Franchisee2] - Acknowledgement from Franchisee 2 
     INFO  [ProductMgtSystem.Subscribers.InventoryControl] - Database updated with the new price for the specified product
    ```

### <a name="unit-testing"></a> Writing unit tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g.: testProductAdminService()

This guide contains unit test case for the HTTP service `productAdminService` from file `product_admin_portal.bal`. Test file is in the same package in which the above-mentioned file is located.

To run the unit test, go to the sample root directory and run the following command
   ```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina test ProductMgtSystem/Publisher/
   ```

To check the implementation of this test file, refer [product_admin_portal_test.bal](https://github.com/pranavan15/messaging-with-kafka/blob/master/ProductMgtSystem/Publisher/product_admin_portal_test.bal).

## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the services that you developed above, in your local environment. You can create the Ballerina executable archives (.balx) first and then run them in your local environment as follows,

Building 
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina build ProductMgtSystem/Publisher/

    <SAMPLE_ROOT_DIRECTORY>$ ballerina build ProductMgtSystem/Subscribers/<Subscriber_Package_Name>/

   ```

Running
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run <Exec_Archive_File_Name>

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


## P.S.

Due to an [issue](https://github.com/wso2-ballerina/package-kafka/issues/2), Ballerina Kafka Connector does not work with Ballerina versions later 0.96.0 (exclusive). Therefore, when trying this guide use Ballerina version 0.96.0.
