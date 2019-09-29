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

import ballerina/log;
import wso2/amazonsqs;

// Executes the workers in the guide
public function main(string... args) {

    // queueCreator, creates a new queue
    worker queueCreator {
        log:printInfo("queueCreator started ....");
        string queueResourcePath = "";
        // Create the queue
        string|error queueURL = createNotificationQueue("fireNotifications");
        // When the queue creation operation is successful
        if (queueURL is string) {
            // Extract the SQS queue resource path from the URL
            queueResourcePath = amazonsqs:splitString(queueURL, "amazonaws.com", 1);
            log:printInfo("Queue Resource Path: " + queueResourcePath);
        } else {
            log:printError("Error occurred while creating the queue.");
        }

        // Send the resource path of the queue to the fire notifier
        queueResourcePath -> fireNotifier;
        // Send the resource path of the queue to the fire listener
        queueResourcePath -> fireListener;
    }

    // Fire notifier worker which publishes to the SQS queue
    worker fireNotifier {
        log:printInfo("fireNotifier started ....");
        // Get the resource path from the queue creator
        string queueResourcePath = <- queueCreator;
        // Starts to periodically send fire alerts
        periodicallySendFireNotifications(queueResourcePath);
    }

    // Fire listener which listens to the SQS queue
    worker fireListener {
        log:printInfo("fireListener started ....");
        // Get the resource path from the queue creator
        string queueResourcePath = <- queueCreator;
        // Starts to listen for the fire alerts via polling
        listenToFireAlarm(queueResourcePath);
    }

    // Starts from the queue creator worker
    wait queueCreator;

}
