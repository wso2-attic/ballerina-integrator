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
service fruitConsumerService on fruitConsumer {
    // Trigger whenever a message is added to the subscribed topic
    resource function onMessage(kafka:Consumer productConsumer, kafka:ConsumerRecord[] records) returns error? {
        foreach var entry in records {
            byte[] serializedMessage = entry.value;
            string stringMessage = check strings:fromBytes(serializedMessage);

            io:StringReader sr = new (stringMessage);
            json jsonMessage = check sr.readJson();

            log:printInfo("Fruits Consumer Service : Product Received");
            log:printInfo("Name : " + jsonMessage.Name.toString());
            log:printInfo("Price : " + jsonMessage.Price.toString());
        }
    }
}
