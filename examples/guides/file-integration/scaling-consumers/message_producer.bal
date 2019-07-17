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

type Config record {
    string fileNamePattern;
    string destFolder;
    string errFolder;
    Operation opr;
};

// Define a record to get the following configurations for processing the file.
Config conf = {
    fileNamePattern: ".*.json",
    destFolder: "/movedFolder",
    errFolder: "/errFoldr",
    opr: MOVE
};

// Creating a ftp listener instance by defining the configuration.
listener ftp:Listener remoteServer = new({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    pollingInterval:config:getAsInt("FTP_POLLING_INTERVAL"),
    fileNamePattern:conf.fileNamePattern,  
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: "/newFolder"
});

//Initialize a JMS connection with the provider.
jms:Connection jmsConnection = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection.
jms:Session jmsSession = new(jmsConnection, {
    acknowledgementMode: "AUTO_ACKNOWLEDGE"
});

jms:QueueSender queueSender = new(jmsSession, queueName = "FileQueue");

service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("Added file path: " + v1.path);

            var msg = jmsSession.createTextMessage(v1.path);
            if (msg is error) {
                log:printError("Error occurred while creating message", err = msg);
            } else {
                var result = queueSender->send(msg);
                io:println("################", result);
                if (result is error) {
                    log:printError("Error occurred while sending message", err = result);
                }
            }
        }
    }
}

