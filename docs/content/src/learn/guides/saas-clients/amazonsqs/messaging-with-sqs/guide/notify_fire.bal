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

// periodicallySendFireNotifications, which periodically send fire alerts to Amazon SQS queue
function periodicallySendFireNotifications(string queueResourcePath) {

    // Amazon SQS client configuration
    amazonsqs:Configuration configuration = {
        accessKey: config:getAsString("ACCESS_KEY_ID"),
        secretKey: config:getAsString("SECRET_ACCESS_KEY"),
        region: config:getAsString("REGION"),
        accountNumber: config:getAsString("ACCOUNT_NUMBER")
    };

    // Amazon SQS client
    amazonsqs:Client sqsClient = new(configuration);

    while (true) {

        // Wait for 5 seconds
        runtime:sleep(5000);
        string queueUrl = "";

        // Send a fire notification to the queue
        amazonsqs:OutboundMessage|error response = sqsClient->sendMessage("There is a fire!", 
            queueResourcePath, {});
        // When the response is valid
        if (response is amazonsqs:OutboundMessage) {
            log:printInfo("Sent an alert to the queue. MessageID: " + response.messageId);
        } else {
            log:printError("Error occurred while trying to send an alert to the SQS queue!");
        }
    }

}
