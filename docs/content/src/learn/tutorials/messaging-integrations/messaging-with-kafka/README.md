# Messaging with Kakfa

Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records get published. Topics in Kafka are always multi-subscriber.

This guide walks you through the process of messaging with Apache Kafka using Ballerina language. The following figure illustrates the publish-subscribe messaging use-case. 

![messaging_with_kafka](/resources/diagram.png "Messaging with Kafka")

## What you'll build

To understand how you can use Kafka for 'publish-subscribe' messaging, lets consider a real-world use case of a Product Management System. This product management system consists of a product admin portal where the product administrator can update the price for a product. Based on the content of the message sent to the product admin service, it is filtered to different partitions in the Kafka Topic.  

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

* Create a new Ballerina project named `messaging-with-kakfa`.

```bash
$ ballerina new messaging-with-kafka
```

* Navigate to the messaging-with-kafka directory.

* Add a new module named `product_management_system` to the project.

```bash
$ ballerina add product_management_system
```

* Open the project with VS Code. The project structure will be similar to the following.

```shell
messaging-with-kafka
├── Ballerina.toml
└── src
    └── product_management_system
        ├── main.bal
        ├── Module.md
        ├── resources
        └── tests
            ├── main_test.bal
            └── resources
```
We can remove the file `main-test.bal` for the moment, since we are not writing any tests for our service.

Lets get started with the implementation of a Kafka Service called `product_admin_service` which acts as the message publisher. It contains an HTTP Service that is used by a product admin to update the price of a product.

Let's see how to add the Kafka configurations for a Kafka publisher written in Ballerina language. Refer to the code segment given below.

<!-- INCLUDE_CODE_SEGMENT: { file: src/product_management_system.bal, segement: kafka_producer_config } -->

A Kafka producer in Ballerina needs to consist of a `kafka:Producer` object that specifies the required configurations for a Kafka publisher.

The `product_admin_service.bal` is a Kafka topic publisher which accepts HTTP requests and routes the serialized message to a partition in the topic based on the content of the recieved payload. In this case it filters for product type.


* Create a new file named `product_admin_service.bal` with the following content

**product_admin_service.bal**

<!-- INCLUDE_CODE: src/product_management_system/product_admin_service.bal -->




Let us consider the consumer services, `consumer1` and `consumer2`

<!-- INCLUDE_CODE_SEGMENT: { file: src/consumer1.bal, segment: kafka_consumer_config } -->

We make use of a `partitionAssignmentStrategy` to assign the consumer to a particular topic partition.

* Create a new file named `consumer1` file under `product_management_system` with the following content.

**consumer1.bal**
<!-- INCLUDE_CODE: src/product_management_system/consumer1.bal -->

* Likewise, let's create another file `consumer2.bal` with the following content.

**consumer2.bal**
<!-- INCLUDE_CODE: src/product_management_system/consumer2.bal -->


In the above code, resource function `onMessage` is triggered whenever a message published is to the topic specified.


## Testing

* First, start the `ZooKeeper` instance with the default configurations by entering the following command in a terminal from `<KAFKA_HOME_DIRECTORY>`.

 ```bash
$ bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
 ```

**Tip**: `-daemon` flag is optional, use this if you want to run kafka server as a daemon) 

  Here we start a zookeeper with default configurations (on `port:2181`).

* Start a single `Kafka broker` instance with the default configurations by entering the following command  in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-server-start.sh -daemon config/server.properties
```

**Tip**: `-daemon` flag is optional, use this if you want to run Kafka server as a daemon) 
  
  Here we started the Kafka server on `host:localhost` and `port:9092`. Now we have a working Kafka cluster.

* Create a new topic called `product-price` on the Kafka cluster by entering the following command in a terminal from `<KAFKA_HOME_DIRECTORY>`.

```bash
   $ bin/kafka-topics.sh --create --topic product-price --zookeeper \
   localhost:2181 --replication-factor 1 --partitions 2
```

Here we created a new topic that consists of two partitions with a single replication factor.

* Now we shall build the module. Navigate to the messaging-with-kafka directory and execute the following command.

```bash
$ ballerina build messaging-with-kafka
```

This would create the executables.

* Run the `product_management_system.jar` created in the above step.

* Invoke the `product_admin_service` by sending a valid POST request

```bash
curl -v POST -d \
   '{ "Product": "Carrot","Type": "Vegetable","Price": "100.00"}' \
   "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
```

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
