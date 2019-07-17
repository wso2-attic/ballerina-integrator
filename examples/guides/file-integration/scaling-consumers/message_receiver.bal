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

import wso2/ftp;
import ballerina/log;
import ballerina/io;
import ballerina/internal;
import ballerina/config;
import ballerina/http;
import ballerina/jms;
import wso2ftputils;

public const MOVE = "MOVE";
public const DELETE = "DELETE";
public const ERROR = "ERROR";

// Define the union type of the actions that can be performed after processing the file.
public type Operation MOVE|DELETE|ERROR;

// Defining the configuration of the ftp client endpoint.
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};

// Creating a ftpClient object.
ftp:Client ftpClient = new(ftpConfig);

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
});

// Initialize a JMS session on top of the created connection
jms:Session jmsSessionRe = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
});

// Initialize a queue receiver using the created session
listener jms:QueueReceiver jmsConsumer = new(jmsSessionRe, queueName = "FileQueue");

service fileConsumingSystem on jmsConsumer {
    // Triggered whenever an order is added to the 'FileQueue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New File received from the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("File Details: " + stringPayload);

            //processing logic
            var proRes = processFile(stringPayload);

            // Moving the file to another location on the same ftp server after processing.
            if (proRes == MOVE) {
                string destFilePath = createFolderPath(stringPayload, conf.destFolder);
                error? renameErr = ftpClient->rename(stringPayload, destFilePath);
            } else if (proRes == DELETE) {
                error? fileDelCreErr = ftpClient->delete(stringPayload);
                log:printInfo("Deleted File after processing");
            } else {
                string errFoldPath = createFolderPath(stringPayload, conf.errFolder);
                error? processErr = ftpClient->rename(stringPayload, errFoldPath);
            }
        } else {
            log:printInfo("Error occurred while retrieving the order details");
        }       
    }
}

// Processing logic that needs to be done on the file content based on the file type.
public function processFile(string sourcePath) returns Operation {

    var getResult = ftpClient->get(sourcePath);
    Operation res = MOVE;

    if (getResult is io:ReadableByteChannel) {
        json|error jsonFileRes = wso2ftputils:readJsonFile(getResult);
        if (jsonFileRes is json) {
            log:printInfo("File read successfully");
            if (conf.opr == MOVE) {
                res = MOVE;
            } else if (conf.opr == DELETE) {
                res = DELETE;
            }
        } else {
            log:printError("Error in reading file", err = jsonFileRes);
            res = ERROR;
        }
    } else {
        log:printError("Error in reading file.");
        res = ERROR;
    }
    return res;
}

// Generating file paths to move the processed file.
public function createFolderPath(string v2, string folderPath) returns string {
    string p2 = createPath(v2);
    string path = folderPath + "/" + p2;
    return path;
}

public function createPath(string v3) returns string {
    int subString = v3.lastIndexOf("/");
    int length = v3.length();
    string subPath = v3.substring((subString + 1), length);
    return subPath;
}

