import ballerina/http;
import ballerina/kafka;
import ballerina/log;

// CODE-SEGMENT-BEGIN: kafka_producer_config
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientId: "kafka-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer kafkaProducer = new(producerConfigs);
// CODE-SEGMENT-END: kafka_producer_config

// HTTP Service Endpoint
listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/product" }
service productAdminService on httpListener {

    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    resource function updatePrice(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        json reqPayload = check request.getJsonPayload();
        log:printInfo("ProductManagementService : Received Payload");

        var productName = reqPayload.Product;
        var productType = reqPayload.Type;
        var productPrice = reqPayload.Price;

        // Construct message to be published to the Kafka Topic
        json productInfo = {
            "Name" : productName.toString(),
            "Price" : productPrice.toString()
        };

        // Serialize the message
        byte[] kafkaMessage = productInfo.toJsonString().toBytes();

        if (productType.toString() == "Fruit") {
            log:printInfo("ProductManagementService : Sending message to Partition 0");
            var sendResult = kafkaProducer->send(kafkaMessage, "product-price", partition = 0);
        } else if (productType.toString() == "Vegetable") {
            log:printInfo("ProductManagementService : Sending message to Partition 1");
            var sendResult = kafkaProducer->send(kafkaMessage, "product-price", partition = 1);
        }
        
        response.setJsonPayload({ "Status" : "Success" });
        var responseResult = caller->respond(response);
    }
}
