// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import wso2/kafka;

// Kafka consumer endpoint
endpoint kafka:ConsumerEndpoint consumer {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "inventorySystemd",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval:1000
};

// Kafka service that listens from the topic 'product-price'
// 'inventoryControlService' subscribed to new product price updates from the product admin and updates the Database
service<kafka:Consumer> kafkaService bind consumer {
    // Triggered whenever a message added to the subscribed topic
    onMessage(kafka:ConsumerAction consumerAction, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service, We process each one by one.
        int counter = 0;
        while (counter < lengthof records) {
            blob serializedMsg = records[counter].value;
            // Convert the serialized message to string message
            string msg = serializedMsg.toString("UTF-8");
            log:printInfo("New message received from the product admin");
            // log the retrieved Kafka record
            log:printInfo("Topic: " + records[counter].topic + "; Received Message: " + msg);
            // Mock logic
            // Update the database with the new price for the specified product
            log:printInfo("Database updated with the new price for the specified product");
            counter = counter + 1;
        }
    }
}
