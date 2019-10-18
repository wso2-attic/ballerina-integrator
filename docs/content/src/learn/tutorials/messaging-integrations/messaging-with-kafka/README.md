# Messaging with Kakfa

Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records get published. Topics in Kafka are always multi-subscriber.

This guide walks you through the process of messaging with Apache Kafka using Ballerina language.

## What you'll build

To understand how you can use Kafka for 'publish-subscribe' messaging, lets consider a real-world use case of a Product Management System. This product management system consists of a product admin portal where the product administrator can update the price for a product. Based on the content of the message sent to the product admin service, it is filtered to different partitions in the Kafka Topic.  

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

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

Lets get started with the implementation of a Kafka Service called `product_admin_service` which acts as the message publisher. It contains an HTTP Service that is used by a product admin to update the price of a product.

Let's see how to add the Kafka configurations for a Kafka publisher written in Ballerina language. Refer to the code segment given below.

<!-- INCLUDE_CODE_SEGMENT: { file: src/product_management_system.bal, segement: kafka_producer_config } -->

A Kafka producer in Ballerina needs to consist of a `kafka:Producer` object that specifies the required configurations for a Kafka publisher.

Let us now see the complete implementation of the `product_admin_service`, which is a Kafka topic publisher. This publisher accepts HTTP requests and routes the serialized message to a partition in the topic based on the content of the recieved payload. In this case it filters for product type.

#### product_admin_service.bal

<!-- INCLUDE_CODE: src/product_management_system/product_admin_service.bal -->

Let us consider the consumer services, `consumer1` and `consumer2`

<!-- INCLUDE_CODE_SEGMENT: { file: src/consumer1.bal, segment: kafka_consumer_config } -->

We make use of a `partitionAssignmentStrategy` to assign the consumer to a particular topic partition.

Let us now see the complete implementation of a consumer.

#### consumer1.bal
<!-- INCLUDE_CODE: src/product_management_system/consumer1.bal -->

In the above code, resource function `onMessage` is triggered whenever a message published is to the topic specified.

## Deployment

Once you are done with the development, you can deploy the services using the method listed below.

### Deploying locally

To deploy locally, navigate to the `product_management_system` folder and execute the following command.

```bash
  $ ballerina build -a
```

This builds all the necessary .bal files that produce a product_management_system.jar file.

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

**Tip**: `-daemon` flag is optional, use this if you want to run kafka server as a daemon) 

  Here we start a zookeeper with default configurations (on `port:2181`).

- Start a single `Kafka broker` instance with the default configurations by entering the following command  in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-server-start.sh -daemon config/server.properties
```

**Tip**: `-daemon` flag is optional, use this if you want to run Kafka server as a daemon) 
  
  Here we started the Kafka server on `host:localhost` and `port:9092`. Now we have a working Kafka cluster.

- Create a new topic called `product-price` on the Kafka cluster by entering the following command in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-topics.sh --create --topic product-price --zookeeper \
   localhost:2181 --replication-factor 1 --partitions 2
```

Here we created a new topic that consists of two partitions with a single replication factor.

- Run the `product_management_system.jar` to run all the built services.

- Invoke the `product_admin_service` by sending a valid POST request

```bash
curl -v POST -d \
   '{ "Product": "Carrot","Type": "Vegetable","Price": "100.00"}' \
   "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
```

### Output

Based on the 'Type' specified in the request, the message is filtered into two partitions. One consumer is subscribed to one partition, which receives products of Type 'Vegetable' while the other receives products of Type 'Fruit'.

The following message will be displayed on the terminal.

```bash
ProductManagementService : Received payload
ProductManagementService : Sending message to Partition 0
ProductConsumerService1 : Product Received
Name : Apple
Price : Fruit

```

And `{"Status": "Success"}` message is received from the product_admin_service.
