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

import ballerina/io;
import wso2/kafka;
import ballerina/encoding;

// Kafka consumer listener configurations
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "franchisee2",
    // Listen from topic 'product-price'
    topics: ["product-price"],
    // Poll every 1 second
    pollingInterval: 1000
};

// Create kafka listener
listener kafka:SimpleConsumer consumer = new(consumerConfig);

// Kafka service that listens from the topic 'product-price'
// 'FranchiseeService2' subscribed to new product price updates from the product admin
service franchiseeService2 on consumer {
    // Triggered whenever a message added to the subscribed topic
    resource function onMessage(kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service, We process each one by one.
        foreach var entry in records {
            byte[] serializedMsg = entry.value;
            // Convert the serialized message to string message
            string msg = encoding:byteArrayToString(serializedMsg);
            io:println("[INFO] New message received from the product admin");
            // log the retrieved Kafka record
            io:println("[INFO] Topic: " + entry.topic + "; Received Message: " + msg);
            // Acknowledgement
            io:println("[INFO] Acknowledgement from Franchisee 2");
        }
    }
}
