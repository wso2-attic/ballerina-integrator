import ballerina/kafka;
import ballerina/io;
import ballerina/lang.'string as strings;

// Kafka Consumer Configuration
kafka:ConsumerConfig consumer2 = {
    bootstrapServers: "localhost:9092",
    groupId: "consumer",
    topics: ["product-price"],
    pollingIntervalInMillis: 1000,
    partitionAssignmentStrategy: "org.apache.kafka.clients.consumer.RoundRobinAssignor"
};

// Kafka Listener
listener kafka:Consumer productConsumer2 = new (consumer2);

// Service that listens to the particular topic
service productConsumerService2 on productConsumer2 {
    // Trigger whenever a message is added to the subscribed topic
    resource function onMessage(kafka:Consumer productConsumer, kafka:ConsumerRecord[] records) returns error? {
        foreach var entry in records {
            byte[] serializedMessage = entry.value;
            string|error stringMessage = strings:fromBytes(serializedMessage);

            if (stringMessage is string) {
                io:StringReader sr = new (stringMessage);
                json jsonMessage = check sr.readJson();

                io:println("ProductConsumerService2 : Product Received");
                io:println("Name : ", jsonMessage.Name);
                io:println("Price : ", jsonMessage.Price);
            }
        }
    }
}
