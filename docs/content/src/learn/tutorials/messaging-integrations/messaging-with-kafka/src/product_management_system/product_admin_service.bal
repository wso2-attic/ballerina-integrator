// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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

kafka:Producer kafkaProducer = new (producerConfigs);
// CODE-SEGMENT-END: kafka_producer_config

// HTTP Service Endpoint
listener http:Listener httpListener = new (9090);

@http:ServiceConfig {basePath: "/product"}
service productAdminService on httpListener {

    @http:ResourceConfig {methods: ["POST"], consumes: ["application/json"], produces: ["application/json"]}
    resource function updatePrice(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;

        json | error reqPayload = request.getJsonPayload();

        if (reqPayload is json) {
            log:printInfo("ProductManagementService : Received Payload");

            // Construct message to be published to the Kafka Topic
            json productInfo = {
                "Name": reqPayload.Product.toString(),
                "Price": reqPayload.Price.toString()
            };

            // Serialize the message
            byte[] kafkaMessage = productInfo.toJsonString().toBytes();

            if (reqPayload.Type.toString() == "Fruit") {
                log:printInfo("ProductManagementService : Sending message to Partition 0");
                var sendResult = kafkaProducer->send(kafkaMessage, "product-price", partition = 0);
            } else if (reqPayload.Type.toString() == "Vegetable") {
                log:printInfo("ProductManagementService : Sending message to Partition 1");
                var sendResult = kafkaProducer->send(kafkaMessage, "product-price", partition = 1);
            } else {
                log:printInfo("ProductManagementService : Product type not recognized");
            }

            response.setJsonPayload({"Status": "Success"});
            var responseResult = caller->respond(response);
        }
    }
}
