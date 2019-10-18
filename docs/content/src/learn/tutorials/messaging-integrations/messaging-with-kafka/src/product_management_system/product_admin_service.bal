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
