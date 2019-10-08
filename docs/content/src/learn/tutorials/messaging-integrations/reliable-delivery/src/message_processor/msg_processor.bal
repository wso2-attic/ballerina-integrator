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
import ballerina/log;
import wso2/storeforward;

public function main(string... args) {

    log:printInfo("Listening for new order requests...");

    // Configure message store to consume stock orders
    storeforward:MessageStoreConfiguration storeConfig = {
            messageBroker: "ACTIVE_MQ",
            providerUrl: "tcp://localhost:61616",
            queueName: "item_orders"
        };

    // Configure processor to send the message to the backend every second
    storeforward:ForwardingProcessorConfiguration processorConfig = {
        storeConfig: storeConfig,
        HttpEndpointUrl: "http://localhost:9090/sales/save-order",
        pollTimeConfig: 1000,
        retryInterval: 3000,
        maxRedeliveryAttempts: 5
    };

    // Initialize and start processor to run periodically
    var stockOrderProcessor = new storeforward:MessageForwardingProcessor(processorConfig, handleResponse);
    if (stockOrderProcessor is error) {
        log:printError("Error while initializing message processor.", err = stockOrderProcessor);
        panic stockOrderProcessor;
    } else {
        var isStart = stockOrderProcessor. start();
        if (isStart is error) {
            panic isStart;
        } else {
            stockOrderProcessor.keepRunning();
        }
    }
}

// Process the response received by stock quote service
function handleResponse(http:Response response) {
    int statusCode = response.statusCode;
    if (statusCode == 200) {
        log:printInfo("Stock order persisted sucessfully.");
    } else {
        log:printError("Error status code " + statusCode.toString() + " received from the stock quote service ");
    }
}
