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
import ballerina/io;
import ballerina/log;
import wso2/ftp;
import wso2/mongodb;

mongodb:ClientEndpointConfig mongoConfig = {
    host: config:getAsString("MONGO_HOST"),
    dbName: config:getAsString("MONGO_DB_NAME"),
    username: config:getAsString("MONGO_USERNAME"),
    password: config:getAsString("MONGO_PASSWORD"),
    options: {sslEnabled: false, serverSelectionTimeout: 500}
};

listener ftp:Listener ftpListener = new ({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_PORT"),
    pollingInterval: 30000,

    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: config:getAsString("FTP_PATH")
});

ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};
ftp:Client ftp = new (ftpConfig);
mongodb:Client mongoClient = check new (mongoConfig);

service ftpServerConnector on ftpListener {
    resource function onFileChange(ftp:WatchEvent fileEvent) returns error? {
        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("Added file path  " + v1.path + " to FTP location");

            var y = insertToMongo(v1.path);
        }
    }
}

function readFile(string sourcePath) returns @untainted json[] | error {
    io:ReadableByteChannel getResult = check ftp->get(sourcePath);

    io:ReadableCharacterChannel readableCharChannel = new io:ReadableCharacterChannel(getResult, "UTF-8");
    io:ReadableCSVChannel csvChannel = new io:ReadableCSVChannel(readableCharChannel);
    json[] j2 = [];
    int i = 0;
    while (csvChannel.hasNext()) {
        var records = check csvChannel.getNext();
        json j1 = {x: records};
        j2[i] = j1;

        i = i + 1;
    }
    var result = csvChannel.close();
    return j2;
}

function insertToMongo(string path) returns error? {
    json[] | error data = readFile(path);

    if (data is json) {
        foreach json doc in data {
            var insertResult = mongoClient->insert("projects", doc);
        }
    } else {
        log:printError("Error occured in reading the file");
    }

    handleInsert(data);
}

function handleInsert(json | error returned) {
    if (returned is json) {
        log:printInfo("Successfully inserted data to mongo db");
    } else {
        log:printError(returned.reason());
    }
}
