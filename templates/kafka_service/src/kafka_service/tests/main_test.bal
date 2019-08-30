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

import ballerina/config;
import ballerina/encoding;
import ballerina/kafka;
import ballerina/runtime;
import ballerina/test;

string producerMsg = "test string";
boolean isReceived = false;

# Before test function

function beforeFunc () {
    kafka:ProducerConfig producerConfigs = {
        bootstrapServers: config:getAsString("BOOTSTRAP_SERVERS", "localhost:9092"),
        clientId: "test-producer",
        acks: kafka:ACKS_ALL,
        retryCount: 3
    };

    kafka:Producer kafkaProducer = new(producerConfigs);

    byte[] byteMsg = producerMsg.toBytes();
    var result = kafkaProducer->send(byteMsg, config:getAsString("TEST_TOPIC", "test-topic"));
    runtime:sleep(10000);
}

# Test function

@test:Config{
    before:"beforeFunc"
}
function testFunction () {
    kafka:ConsumerConfig consumerConfigs = {
        bootstrapServers: config:getAsString("BOOTSTRAP_SERVERS", "localhost:9092"),
        groupId: "test-group",
        clientId: "test-consumer",
        offsetReset: "earliest",
        topics: [config:getAsString("TEST_TOPIC", "test-topic")],
        autoCommit:false
    };

    kafka:Consumer kafkaConsumer = new(consumerConfigs);

    var results = kafkaConsumer->poll(1000);
    if (results is error) {
        test:assertFail("Error occurred while polling..");
    } else {
        foreach var kafkaRecord in results {
            byte[] serializedMsg = kafkaRecord.value;
            string msg = encoding:byteArrayToString(serializedMsg);
            if (msg == producerMsg) {
                isReceived = true;
                break;
            }
        }
        test:assertTrue(isReceived , msg = "Failed!");
    }
}
