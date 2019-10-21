import ballerina/kafka;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/io;

// CODE-SEGMENT-BEGIN: kafka_consumer_config
kafka:ConsumerConfig fruitConsumerConfig = {
    bootstrapServers: "localhost:9092",
    groupId: "consumer",
    topics: ["product-price"],
    pollingIntervalInMillis: 1000,
    partitionAssignmentStrategy: "org.apache.kafka.clients.consumer.RoundRobinAssignor"
};

listener kafka:Consumer fruitConsumer = new (fruitConsumerConfig);
// CODE-SEGMENT-END: kafka_consumer_config

// Service that listens to the particular topic
service productConsumerService1 on fruitConsumer {
    // Trigger whenever a message is added to the subscribed topic
    resource function onMessage(kafka:Consumer productConsumer, kafka:ConsumerRecord[] records) returns error? {
        foreach var entry in records {
            byte[] serializedMessage = entry.value;
            string|error stringMessage = strings:fromBytes(serializedMessage);

            if (stringMessage is string) {
                io:StringReader sr = new (stringMessage);
                json jsonMessage = check sr.readJson();

                log:printInfo("Fruits Consumer Service : Product Received");
                log:printInfo("Name : " + jsonMessage.Name.toString());
                log:printInfo("Price : " + jsonMessage.Price.toString());
            }
        }
    }
}
