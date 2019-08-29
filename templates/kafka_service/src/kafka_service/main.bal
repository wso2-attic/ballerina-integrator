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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/encoding;
import ballerina/io;
import ballerina/kafka;

string topic = config:getAsString("CONSUMER_TOPIC", "consumer-topic");

kafka:ConsumerConfig consumerConfigs = {
    bootstrapServers: config:getAsString("BOOTSTRAP_SERVERS"),
    groupId: config:getAsString("GROUP_ID", "consumer-service-group"),
    clientId: config:getAsString("CONSUMER_CLIENT_ID", "service-consumer"),
    offsetReset: "earliest",
    topics: [topic],
    autoCommit:false
};

listener kafka:Consumer kafkaConsumer = new(consumerConfigs);

service kafkaService on kafkaConsumer {
    resource function onMessage(
        kafka:Consumer consumer,
        kafka:ConsumerRecord[] records,
        kafka:PartitionOffset[] offsets,
        string groupId
    ) {
        // Dispatched set of Kafka records to service, We process each one by one.
        foreach var kafkaRecord in records {
            processKafkaRecord(kafkaRecord);
        }
    }
}

function processKafkaRecord(kafka:ConsumerRecord kafkaRecord) {
    byte[] serializedMsg = kafkaRecord.value;
    string msg = encoding:byteArrayToString(serializedMsg);
    // Print the retrieved Kafka record.
    io:println("Topic: " + kafkaRecord.topic + " Partition: " + io:sprintf("%s", kafkaRecord.partition)
    + " Received Message: " + msg);
}
