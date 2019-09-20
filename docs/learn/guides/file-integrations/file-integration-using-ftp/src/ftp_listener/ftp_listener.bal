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
import ballerina/config;
import wso2/ftp;

type Config record {
    string fileNamePattern;
    string filePath;
};

Config conf = {
    fileNamePattern: config:getAsString("FTP_FILE_NAME_PATTERN"),
    filePath: config:getAsString("FTP_LISTENER_PATH")
};

map<int> fileMap = {};

listener ftp:Listener dataFileListener = new({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: conf.filePath,
    fileNamePattern: conf.fileNamePattern,
    pollingInterval: config:getAsInt("FTP_POLLING_INTERVAL")
});

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

ftp:Client ftpClient = new(ftpConfig);

service dataFileService on dataFileListener {
    resource function processDataFile(ftp:WatchEvent fileEvent) {

        foreach ftp:FileInfo file in fileEvent.addedFiles {
            log:printInfo("Added file path: " + file.path);
            processNewFile(file.path);
        }
        foreach string file in fileEvent.deletedFiles {
            log:printInfo("Deleted file path: " + file);
            processDeletedFile(file);
        }
    }
}

function processNewFile(string filePath) {
    int|error fileSize = ftpClient -> size(filePath);
    if(fileSize is int){
        fileMap[filePath] = fileSize;
        log:printInfo("Added file: " + filePath + " - " + fileSize.toString());
    } else {
        log:printError("Error in getting file size", fileSize);
    }
}

function processDeletedFile(string filePath) {
    if(fileMap.hasKey(filePath)){
        int removedElement = fileMap.remove(filePath);
        log:printInfo("Deleted file: " + filePath);
    }
}
