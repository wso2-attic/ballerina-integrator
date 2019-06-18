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
import wso2ftputils;

string fNamePattern = ".*.json";
string destFolder = "/movedFolder";

// Creating a ftp listener instance by defining the configuration.
listener ftp:Listener remoteServer = new({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    pollingInterval:config:getAsInt("FTP_POLLING_INTERVAL"),
    fileNamePattern:fNamePattern,
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: "/newFolder"
});

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

ftp:Client ftpClient = new(ftpConfig);

service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("Added file path: " + v1.path);

            processFile(untaint v1.path);

            string destFilePath = createDestPath(v1);

            // Moving the file to another location on the same ftp server after processing.
            error? renameErr = ftpClient->rename(v1.path, destFilePath);       
        }

        foreach string v2 in m.deletedFiles {
            log:printInfo("Deleted file path: " + v2);
        }
    }
}

// Processing logic that needs to be done on the file content based on the file type.
public function processFile(string sourcePath) {
  
   var getResult = ftpClient->get(sourcePath);
  
   if(getResult is io:ReadableByteChannel){
       json jsonFile = wso2ftputils:readJsonFile(getResult);          
   } else {
       log:printError("Error in reading file");
   }
}

// Generating the file name of the processed file.
public function createDestPath(ftp:FileInfo v2) returns string {
    int subString = v2.path.lastIndexOf("/");
    int length = v2.path.length();
    string subPath = v2.path.substring((subString + 1), length);
    string destPath = destFolder + "/" + subPath;

    return destPath;
}

