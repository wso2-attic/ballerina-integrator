import ballerina/kafka;
import ballerina/io;
import ballerina/lang.'string as strings;

// CODE-SEGMENT-BEGIN: kafka_consumer_config
kafka:ConsumerConfig consumer1 = {
    bootstrapServers: "localhost:9092",
    groupId: "consumer",
    topics: ["product-price"],
    pollingIntervalInMillis: 1000,
    partitionAssignmentStrategy: "org.apache.kafka.clients.consumer.RoundRobinAssignor"
};

listener kafka:Consumer productConsumer1 = new (consumer1);
// CODE-SEGMENT-END: kafka_consumer_config

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
