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
import ballerina/log;
import ballerina/runtime;
import wso2/amazonsqs;

// listenToFireAlarm, which listens to the Amazon SQS queue for fire notifications with polling
function listenToFireAlarm(string queueResourcePath) {

    // Amazon SQS client configuration
    amazonsqs:Configuration configuration = {
        accessKey: config:getAsString("ACCESS_KEY_ID"),
        secretKey: config:getAsString("SECRET_ACCESS_KEY"),
        region: config:getAsString("REGION"),
        accountNumber: config:getAsString("ACCOUNT_NUMBER")


    };

    // Amazon SQS client
    amazonsqs:Client sqsClient = new(configuration);
    string receivedReceiptHandler = "";

    // Receive a message from the queue
    map<string> attributes = {};
    // MaxNumberOfMessages, the maximum number of messages that can be received per request
    attributes["MaxNumberOfMessages"] = "10";
    // VisibilityTimeout, time allowed to delete after received, in seconds
    attributes["VisibilityTimeout"] = "2";
    // WaitTimeSeconds, waits for this time (in seconds) till messages are collected before received
    attributes["WaitTimeSeconds"] = "1";

    while(true) {

        // Wait for 5 seconds
        runtime:sleep(5000);
        // Receive messages from the queue
        amazonsqs:InboundMessage[]|error response = sqsClient->receiveMessage(queueResourcePath, attributes);

        // When the response is not an error
        if (response is amazonsqs:InboundMessage[]) {

            // When there are messages available in the queue
            if (response.length() > 0) {
                log:printInfo("************** Received fire alerts! ******************");
                int deleteMssageCount = response.length();
                log:printInfo("Going to delete " + deleteMssageCount.toString() + " messages from queue.");

                // Iterate on each message
                foreach var eachResponse in response {

                    // Keep receipt handle for deleting the message from the queue
                    receivedReceiptHandler = eachResponse.receiptHandle;

                    // Delete the received the messages from the queue
                    boolean|error deleteResponse = sqsClient->deleteMessage(queueResourcePath, receivedReceiptHandler);

                    // When the response from the delete operation is valid
                    if (deleteResponse is boolean && deleteResponse) {
                        if (deleteResponse) {
                            log:printInfo("Deleted the fire alert \"" + eachResponse.body + "\" from the queue.");
                        }
                    } else {
                        log:printError("Error occurred while deleting the message.");
                    }
                }
            } else {
                log:printInfo("Queue is empty. No messages to be deleted.");
            }

        } else {
            log:printError("Error occurred while receiving the message.");
        }
    }
}
