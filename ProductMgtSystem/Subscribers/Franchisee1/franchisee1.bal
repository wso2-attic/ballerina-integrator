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

package ProductMgtSystem.Subscribers.Franchisee1;

import ballerina.log;
import ballerina.net.kafka;

// Kafka subscriber configurations
@Description {value:"Service level annotation to provide Kafka consumer configuration"}
@kafka:configuration {
    bootstrapServers:"localhost:9092, localhost:9093",
    // Consumer group ID
    groupId:"franchisee1",
    // Listen from topic 'product-price'
    topics:["product-price"],
    // Poll every 1 second
    pollingInterval:1000
}
// Kafka service that listens from the topic 'product-price'
// 'FranchiseeService1' subscribed to new product price updates from the product admin
service<kafka> franchiseeService1 {
    // Triggered whenever a message added to the subscribed topic
    resource onMessage (kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service and process each one by one
        int counter = 0;
        while (counter < lengthof records) {
            // Get the serialized message
            blob serializedMsg = records[counter].value;
            // Convert the serialized message to string message
            string msg = serializedMsg.toString("UTF-8");
            log:printInfo("New message received from the product admin");
            // log the retrieved Kafka record
            log:printInfo("Topic: " + records[counter].topic + "; Received Message: " + msg);
            // Acknowledgement
            log:printInfo("Acknowledgement from Franchisee 1");
            counter = counter + 1;
        }
    }
}
