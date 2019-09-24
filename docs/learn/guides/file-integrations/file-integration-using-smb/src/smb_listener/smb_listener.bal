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
import wso2/smb;

type Config record {
    string fileNamePattern;
    string filePath;
};

Config conf = {
    fileNamePattern: config:getAsString("SMB_FILE_NAME_PATTERN"),
    filePath: config:getAsString("SMB_LISTENER_PATH")
};

map<int> fileMap = {};

listener smb:Listener dataFileListener = new({
    protocol: smb:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("SMB_USERNAME"),
            password: config:getAsString("SMB_PASSWORD")
        }
    },
    path: conf.filePath,
    fileNamePattern: conf.fileNamePattern,
    pollingInterval: config:getAsInt("SMB_POLLING_INTERVAL")
});

smb:ClientEndpointConfig smbConfig = {
    protocol: smb:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    secureSocket: {
     basicAuth: {
         username: config:getAsString("SMB_USERNAME"),
         password: config:getAsString("SMB_PASSWORD")
     }
    }
};

smb:Client smbClient = new(smbConfig);

service dataFileService on dataFileListener {
    resource function processDataFile(smb:WatchEvent fileEvent) {

        foreach smb:FileInfo file in fileEvent.addedFiles {
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
    int|error fileSize = smbClient -> size(filePath);
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
