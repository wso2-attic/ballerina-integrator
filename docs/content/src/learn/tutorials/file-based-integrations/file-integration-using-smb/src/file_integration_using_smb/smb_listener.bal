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
import wso2/smb;


// Map to store processed file details
map<int> fileMap = {};

// Create Samba Listener
// CODE-SEGMENT-BEGIN: segment_1
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
    path: config:getAsString("SMB_LISTENER_PATH"),
    fileNamePattern: config:getAsString("SMB_FILE_NAME_PATTERN"),
    pollingInterval: config:getAsInt("SMB_POLLING_INTERVAL")
});
// CODE-SEGMENT-END: segment_1

// Configurations for Samba Client
// CODE-SEGMENT-BEGIN: segment_3
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

// Create Samba Client
smb:Client smbClient = new(smbConfig);
// CODE-SEGMENT-END: segment_3

// Service to be invoked on file addition/deletion on Samba server
// CODE-SEGMENT-BEGIN: segment_2
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
// CODE-SEGMENT-END: segment_2

// CODE-SEGMENT-BEGIN: segment_4
// Process newly added files to the server, by adding them to the map
function processNewFile(string filePath) {
    int|error fileSize = smbClient -> size(filePath);
    if(fileSize is int){
        fileMap[filePath] = fileSize;
        log:printInfo("Added file: " + filePath + " - " + fileSize.toString());
    } else {
        log:printError("Error in getting file size", fileSize);
    }
}

// Process deleted files from server, by removing them from the map
function processDeletedFile(string filePath) {
    if(fileMap.hasKey(filePath)){
        int removedElement = fileMap.remove(filePath);
        log:printInfo("Deleted file: " + filePath);
    }
}
// CODE-SEGMENT-END: segment_4
