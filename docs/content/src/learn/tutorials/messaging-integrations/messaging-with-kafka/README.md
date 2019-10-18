# Messaging with Kakfa

Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records get published. Topics in Kafka are always multi-subscriber.

This guide walks you through the process of messaging with Apache Kafka using Ballerina language.

- [Messaging with Kafka](#Messaging-with-Kafka)
  - [What you'll build](#What-youll-build)
  - [Prerequisites](#Prerequisites)
  - [Implementation](#Implementation)
    - [Creating the project structure](#Creating-the-project-structure)
    - [Developing the service](#Developing-the-service)
  - [Deployment](#Deployment)
    - [Deploying locally](#Deploying-locally)
    - [Deploying on Docker](#Deploying-on-Docker)
  - [Testing](#Testing)
    - [Output](#Output)

## What you'll build

To understand how you can use Kafka for 'publish-subscribe' messaging, lets consider a real-world use case of a Product Management System. This product management system consists of a product admin portal which the product administrator can update the price for a product. Based on the content of the message sent to the product admin service, it is filtered to different partitions in the Kafka Topic.  

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE

> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

- [Apache Kafka](https://kafka.apache.org/downloads)
  - Download the binary distribution and extract the contents

### Optional Requirements

- [Docker](https://docs.docker.com/install/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

### Creating the project structure

Ballerina is a complete programming language that supports custom project structures. To implement the scenario in this guide, you can use the following package structure:

```bash
messaging-with-kafka
├── Ballerina.toml
└── src
    └── product_management_system
        ├── product_Admin_Service.bal
        ├── consumer1.bal
        ├── consumer2.bal
        └── resources
```

### Developing the service

Lets get started with the implementation of a Kafka Service called `product_admin_service` which acts as the message publisher. It contains an HTTP Service which is used by a product admin to update the price of a product.

Let's see how to add the Kafka configurations for a Kafka publisher written in Ballerina language. Refer to the code segment given below.

```ballerina
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientId: "kafka-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer kafkaProducer = new(producerConfigs);
```

A Kafka producer in Ballerina needs to consist of a `kafka:Producer` object with specifying the required configurations for a Kafka publisher.

Let us now see the complete implementation of the `product_admin_service`, which is a Kafka topic publisher. This publisher accepts HTTP requests and routes the serialized message to a partition in the topic based on the content of the recieved payload. In this case it filters for product type.

#### product_admin_service.bal

```ballerina
import ballerina/http;
import ballerina/kafka;
import ballerina/io;

// Kafka Producer Configuration
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientId: "kafka-producer",
    acks: "all",
    retryCount: 3
};

// Kafka Producer
kafka:Producer kafkaProducer = new(producerConfigs);

// HTTP Service Endpoint
listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/product" }
service productAdminService on httpListener {

    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    resource function updatePrice(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        json reqPayload = check request.getJsonPayload();
        io:println("ProductManagementService : Received payload");

        var productName = reqPayload.Product;
        var productType = reqPayload.Type;
        var productPrice = reqPayload.Price;

        // Construct message to be published to the Kafka Topic
        json productInfo = {
            "Name" : productName.toString(),
            "Price" : productPrice.toString()
        };

        // Serialize the message
        byte[] serializedMessage = productInfo.toJsonString().toBytes();

        if (productType.toString() == "Fruit") {
            io:println("ProductManagementService : Sending message to Partition 0");
            var sendResult = kafkaProducer->send(serializedMessage, "product-price", partition = 0);
        } else if (productType.toString() == "Vegetable") {
            io:println("ProductManagementService : Sending message to Partition 1");
            var sendResult = kafkaProducer->send(serializedMessage, "product-price", partition = 1);
        }

        response.setJsonPayload({ "Status" : "Success" });
        var responseResult = caller->respond(response);
    }
}
```

Let us consider the consumer services, `consumer1` and `consumer2`

```ballerina
// Kafka Consumer Configuration
kafka:ConsumerConfig consumer1 = {
    bootstrapServers: "localhost:9092",
    groupId: "consumer",
    topics: ["product-price"],
    pollingIntervalInMillis: 1000,
    partitionAssignmentStrategy: "org.apache.kafka.clients.consumer.RoundRobinAssignor"

    listener kafka:Consumer productConsumer1 = new (consumer1);
};
```

We make use of a partitionAssignmentStrategy to assign the consumer to a particular topic partition.

Let us now see the complete implementation of a consumer.

#### consumer1.bal
```ballerina
import ballerina/kafka;
import ballerina/io;
import ballerina/lang.'string as strings;

// Kafka Consumer Configuration
kafka:ConsumerConfig consumer1 = {
    bootstrapServers: "localhost:9092",
    groupId: "consumer",
    topics: ["product-price"],
    pollingIntervalInMillis: 1000,
    partitionAssignmentStrategy: "org.apache.kafka.clients.consumer.RoundRobinAssignor"
};

// Kafka Listener
listener kafka:Consumer productConsumer1 = new (consumer1);

// Service that listens to the particular topic
service productConsumerService1 on productConsumer1 {
    // Trigger whenever a message is added to the subscribed topic
    resource function onMessage(kafka:Consumer productConsumer, kafka:ConsumerRecord[] records) returns error? {
        foreach var entry in records {
            byte[] serializedMessage = entry.value;
            string|error stringMessage = strings:fromBytes(serializedMessage);

            if (stringMessage is string) {
                io:StringReader sr = new (stringMessage);
                json jsonMessage = check sr.readJson();

                io:println("ProductConsumerService1 : Product Received");
                io:println("Name : ", jsonMessage.Name);
                io:println("Price : ", jsonMessage.Price);
            }
        }
    }
}
```

In the above code, resource function `onMessage` will be triggered whenever a message published to the topic specified.


## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

### Deploying locally

To deploy locally, navigate to the `product_management_system` folder and execute the following command.

```bash
  $ ballerina build -a
```
This builds all the necessary bal files which produces a product_management_system.jar file.

To run the service, navigate to the target/bin folder and run the following command

```bash
  $ java -jar product_management_system.jar
```

## Testing

### Invoking the service

- First, start the `ZooKeeper` instance with the default configurations by entering the following command in a terminal from `<KAFKA_HOME_DIRECTORY>`.

 ```bash
    $ bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
 ```

(* `-daemon` flag is optional, use this if you want to run kafka server as a daemon) 

  Here we start a zookeeper with default configurations (on `port:2181`).

- Start a single `Kafka broker` instance with the default configurations by entering the following command  in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-server-start.sh -daemon config/server.properties
```

(* `-daemon` flag is optional, use this if you want to run kafka server as a daemon) 
  
  Here we started the Kafka server on `host:localhost` and `port:9092`. Now we have a working Kafka cluster.

- Create a new topic `product-price` on Kafka cluster by entering the following command in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-topics.sh --create --topic product-price --zookeeper \
   localhost:2181 --replication-factor 1 --partitions 2
```

Here we created a new topic that consists of two partitions with a single replication factor.

- Run the `product_management_system.jar` to run all the built services

- Invoke the `product_admin_service` by sending a valid POST request

```bash
curl -v POST -d \
   '{ "Product": "Carrot","Type": "Vegetable","Price": "100.00"}' \
   "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
```


### Output

Based on the 'Type' specified in request, the message is filtered into two partitions. One consumer is subscribed to one partition, which receives products of Type 'Vegetable' while the other receives products of Type 'Fruit'.

The following message will be displayed on the terminal
```
ProductManagementService : Received payload
ProductManagementService : Sending message to Partition 0
ProductConsumerService1 : Product Received
Name : Apple
Price : Fruit

```

And a `{"Status": "Success"}` message is received from the product_admin_service. 
