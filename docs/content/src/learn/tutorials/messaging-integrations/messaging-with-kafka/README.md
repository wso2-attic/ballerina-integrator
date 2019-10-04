# Messaging with Kafka

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on the process of messaging with Apache Kafka using Ballerina language. You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

Kafka is a distributed, partitioned, replicated commit log service. It provides the functionality of a publish-subscribe messaging system with a unique design. Kafka mainly operates based on a topic model. A topic is a category or feed name to which records get published. Topics in Kafka are always multi-subscriber.

## What you’ll build
To understanding how you can use Kafka for publish-subscribe messaging, let's consider a real-world use case of a product management system. This product management system consists of a product admin portal using which the product administrator can update the price for a product. 
This price update message should be consumed by a couple of franchisees and an inventory control system to take appropriate actions. Kafka is an ideal messaging system for this scenario.
In this particular use case, once the admin updates the price of a product, the update message is published to a Kafka topic called `product-price` to which the franchisees and the inventory control system subscribed to listen. The following diagram illustrates this use case.


![alt text](/docs/content/resources/messaging-with-kafka.svg)


In this example, the Ballerina Kafka Connector is used to connect Ballerina to Apache Kafka. With this Kafka Connector, Ballerina can act as both message publisher and subscriber.

<!-- INCLUDE_MD: ../../../../tutorial-prerequisites.md -->
* [Apache Kafka](https://kafka.apache.org/downloads)
  * Download the binary distribution and extract the contents
* [Ballerina Kafka Connector](https://github.com/wso2-ballerina/package-kafka/releases)
  * Extract `wso2-kafka-<version>.zip`. Run the install.{sh/bat} script to install the package.

<!-- INCLUDE_MD: ../../../../tutorial-get-the-code.md -->

### Optional Requirements

- [Docker](https://docs.docker.com/install/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can [download the git repo](https://github.com/ballerina-guides/messaging-with-kafka/archive/master.zip) and directly move to the "Testing" section by skipping "Implementation" section.    

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
messaging-with-kafka
 └── guide
      ├── franchisee1
      │    └── franchisee1.bal
      ├── franchisee2
      │    └── franchisee2.bal
      ├── inventory_control_system
      │    └── inventory_control_system.bal
      └── product_admin_portal
           ├── product_admin_portal.bal
           └── tests
                └── product_admin_portal_test.bal

```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to above created `messaging-with-kafka/guide` directory and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Implementation

Let's get started with the implementation of a Kafka service, which is subscribed to the Kafka topic `product-price`. Let's consider the `inventory_control_system` for example.
First, let's see how to add the Kafka configurations for a Kafka subscriber written in Ballerina language. Refer to the code segment attached below.

##### Kafka subscriber configurations
```ballerina
// Kafka consumer listener configurations
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "inventorySystem",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval: 1000
};

// Create kafka listener
listener kafka:Consumer consumer = new(consumerConfig);
```

A Kafka subscriber in Ballerina needs to consist of a `kafka:Consumer` listener with providing required configurations for a Kafka subscriber.

The `bootstrapServers` field provides the list of host and port pairs, which are the addresses of the Kafka brokers in a "bootstrap" Kafka cluster. 

The `groupId` field specifies the Id of the consumer group. 

The `topics` field specifies the topics that must be listened by this consumer. 

The `pollingInterval` field is the time interval that a consumer polls the topic. 

Let's now see the complete implementation of the `inventory_control_system`, which is a Kafka topic subscriber.

##### inventory_control_system.bal
```ballerina
import ballerina/io;
import wso2/kafka;
import ballerina/encoding;

// Kafka consumer listener configurations
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "inventorySystem",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval: 1000
};

// Create kafka listener
listener kafka:Consumer consumer = new(consumerConfig);

// Kafka service that listens from the topic 'product-price'
// 'inventoryControlService' subscribed to new product price updates from
// the product admin and updates the Database.
service kafkaService on consumer {
    // Triggered whenever a message added to the subscribed topic
    resource function onMessage(kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service, We process each one by one.
        foreach var entry in records {
            byte[] serializedMsg = entry.value;
            // Convert the serialized message to string message
            string msg = encoding:byteArrayToString(serializedMsg);
            io:println("New message received from the product admin");
            // log the retrieved Kafka record
            io:println("Topic: " + entry.topic + "; Received Message: " + msg);
            // Mock logic
            // Update the database with the new price for the specified product
            io:println("Database updated with the new price of the product");
        }
    }
}
```

In the above code, resource function `onMessage` will be triggered whenever a message published to the topic specified.

To check the implementations of the other subscribers, see [franchisee1.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/guide/franchisee1/franchisee1.bal) and 
[franchisee2.bal](https://github.com/ballerina-guides/messaging-with-kafka/blob/master/guide/franchisee2/franchisee2.bal).


Let's next focus on the implementation of the `product_admin_portal`, which acts as the message publisher. It contains an HTTP service using which a product admin updates the price of a product. 

First, let's see how to add the Kafka configurations for a Kafka publisher written in Ballerina language. Refer to the code segment attached below.

##### Kafka producer configurations

```ballerina
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "basic-producer",
    acks: "all",
    noRetries: 3
};

kafka:Producer kafkaProducer = new(producerConfigs);
```

A Kafka producer in Ballerina needs to consist of a `kafka:Producer` object with specifying the required configurations for a Kafka publisher.

Let's now see the complete implementation of the `product_admin_portal`, which is a Kafka topic publisher. Inline comments added for better understanding.

##### product_admin_portal.bal
```ballerina
import ballerina/http;
import wso2/kafka;

// Constants to store admin credentials
final string ADMIN_USERNAME = "Admin";
final string ADMIN_PASSWORD = "Admin";

// Kafka producer configurations
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "basic-producer",
    acks: "all",
    noRetries: 3
};

kafka:Producer kafkaProducer = new(producerConfigs);

// HTTP service endpoint
listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/product" }
service productAdminService on httpListener {

    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    resource function updatePrice(http:Caller caller, http:Request request) {
        http:Response response = new;
        float newPriceAmount = 0.0;
        json|error reqPayload = request.getJsonPayload();

        if (reqPayload is error) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(response);
        } else {
            json username = reqPayload.Username;
            json password = reqPayload.Password;
            json productName = reqPayload.Product;
            json newPrice = reqPayload.Price;

            // If payload parsing fails, send a "Bad Request" message as the response
            if (username == null || password == null || productName == null || newPrice == null) {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Bad Request: Invalid payload" });
                var responseResult = caller->respond(response);
            }

            // Convert the price value to float
            var result = float.convert(newPrice.toString());
            if (result is error) {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Invalid amount specified" });
                var responseResult = caller->respond(response);
            } else {
                newPriceAmount = result;
            }

            // If the credentials does not match with the admin credentials,
            // send an "Access Forbidden" response message
            if (username.toString() != ADMIN_USERNAME || password.toString() != ADMIN_PASSWORD) {
                response.statusCode = 403;
                response.setJsonPayload({ "Message": "Access Forbidden" });
                var responseResult = caller->respond(response);
            }

            // Construct and serialize the message to be published to the Kafka topic
            json priceUpdateInfo = { "Product": productName, "UpdatedPrice": newPriceAmount };
            byte[] serializedMsg = priceUpdateInfo.toString().toByteArray("UTF-8");

            // Produce the message and publish it to the Kafka topic
            var sendResult = kafkaProducer->send(serializedMsg, "product-price", partition = 0);
            // Send internal server error if the sending has failed
            if (sendResult is error) {
                response.statusCode = 500;
                response.setJsonPayload({ "Message": "Kafka producer failed to send data" });
                var responseResult = caller->respond(response);
            }
            // Send a success status to the admin request
            response.setJsonPayload({ "Status": "Success" });
            var responseResult = caller->respond(response);
        }
    }
}
```

#### Enabling Security for the kafka
Ballerina kafka connector allows to secure a Kafka cluster using Transport Layer Security (TLS) authentication.

##### Generating TLS keys and certificates

Please execute the following bash script to generate the keystore and trust-store for broker (kafka.server.keystore.jks and kafka.server.truststore.jks) and client (kafka.client.keystore.jks and kafka.client.truststore.jks):

```ballerina
#!/bin/bash
PASSWORD=test1234
VALIDITY=365
keytool -keystore kafka.server.keystore.jks -alias localhost -validity $VALIDITY -genkey
openssl req -new -x509 -keyout ca-key -out ca-cert -days $VALIDITY
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.server.keystore.jks -alias localhost -certreq -file cert-file
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.server.keystore.jks -alias localhost -import -file cert-signed
keytool -keystore kafka.client.keystore.jks -alias localhost -validity $VALIDITY -genkey
keytool -keystore kafka.client.keystore.jks -alias localhost -certreq -file cert-file
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.client.keystore.jks -alias localhost -import -file cert-signed
```

##### Configuring TLS authentication for the Kafka broker

We have to configure the following properties in <KAFKA_HOME>/config/server.properties file.

* Configure the required security protocols and ports for the listeners.
```ballerina
listeners=SSL://<your.host.name>:9093
```

* Select SSL as the security protocol for inter-broker communication.
```ballerina
security.inter.broker.protocol=SSL
```

* Configure the following TLS protocol-specific properties
```ballerina
ssl.client.auth=required
ssl.keystore.location={file-path}/kafka.server.keystore.jks
ssl.keystore.password=test1234
ssl.key.password=test1234
ssl.truststore.location={file-path}/kafka.server.truststore.jks
ssl.truststore.password=test1234
```

##### Configuring TLS authentication for Kafka subscribers & producers

Let's see a sample for the Kafka topic publisher with SSL parameters.

##### message_producer_with_ssl.bal
```ballerina
import wso2/kafka;
import ballerina/log;

kafka:ProducerConfig producerConfigs = {
    // Here we create a producer configs with SSL parameters.
    bootstrapServers: "localhost:9093",
    clientID:"basic-producer",
    acks:"all",
    noRetries:3,
    secureSocket: {
        keyStore:{
            location:"<FILE_PATH>/kafka.client.keystore.jks",
            password:"test1234"
        },
        trustStore: {
            location:"<FILE_PATH>/kafka.client.truststore.jks",
            password:"test1234"
        },
        protocol: {
            sslProtocol:"TLS",
            sslProtocolVersions:"TLSv1.2,TLSv1.1,TLSv1",
            securityProtocol:"SSL"
        },
        sslKeyPassword:"test1234"
    }
};

kafka:Producer kafkaProducer = new(producerConfigs);

public function main (string... args) {
    string msg = "Hello World, Ballerina";
    byte[] serializedMsg = msg.toByteArray("UTF-8");
    var sendResult = kafkaProducer->send(serializedMsg, "test-kafka-topic");
    if (sendResult is error) {
        log:printError("Kafka producer failed to send data", err = sendResult);
    }
    var flushResult = kafkaProducer->flushRecords();
    if (flushResult is error) {
        log:printError("Kafka producer failed to flush the records", err = flushResult);
    }
}
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
   
- Start the `productAdminService` (implemented in the above mentioned sample), which is an HTTP service that publishes messages to the Kafka topic by entering the following command from `messaging-with-kafka/guide` directory.
```bash
   $ ballerina run product_admin_portal
```
- Navigate to `messaging-with-kafka/guide` and run the following commands in separate terminals to start the topic subscribers.
```bash
   $ ballerina run inventory_control_system
   $ ballerina run franchisee1
   $ ballerina run franchisee2   
```
   
- Invoke the `productAdminService` by sending a valid POST request.
```bash
   curl -v POST -d \
   '{"Username":"Admin", "Password":"Admin", "Product":"ABC", "Price":100.00}' \
   "http://localhost:9090/product/updatePrice" -H "Content-Type:application/json"
```

- The `productAdminService` sends a response similar to the following (with some additional details).
```
   < HTTP/1.1 200 OK
   ...
   {"Status":"Success"}
```

- Sample outputs in Kafka subscriber services:

All the services will output the following:
```
  [INFO] New message received from the product admin
  [INFO] Topic: product-price; Received Message: {"Product":"ABC", "UpdatedPrice":100.0}
```

Inventory control system:
```
  [INFO] Database updated with the new price of the product
```

Franchisee 1:
```
  [INFO] Acknowledgement from Franchisee 1 
```

Franchisee 2:
```
  [INFO] Acknowledgement from Franchisee 2 
```

## Deployment

Once you are done with the development, you can deploy the services using any of the methods that we listed below. 

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `messaging-with-kafka/guide` and run the following command.
```bash
   $ ballerina build
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output.
```
   ballerina: initiating service(s) in 'target/product_admin_portal.balx'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```
