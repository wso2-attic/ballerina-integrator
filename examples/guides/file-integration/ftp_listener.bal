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

// Creating a ftp listener instance by defining the configuration.
listener ftp:Listener remoteServer = new({
    protocol: ftp:FTP,
    host: "192.168.104.16",
    port: 2121,
    pollingInterval:30000,
    secureSocket: {
        basicAuth: {
            username: "FTPguest",
            password: "123456"
        }
    },
    path: "/newFolder"
});

// Defining the configuration of the ftp client endpoint. 
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: "192.168.104.16",
    port: 2121,
    secureSocket: {
        basicAuth: {
            username: "FTPguest",
            password: "123456"
        }
    }
};

ftp:Client ftpClient = new(ftpConfig);

service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("Added file path: " + v1.path);

           // string[] splitArr = v1.path.split("\\.");
            string filePattern = "*.html";
            string[] splitFileName = splitFilePattern(filePattern);
            string[] splitArr = removePrefix(v1);
            
            if (splitFileName[1] == splitArr[1]) {
                io:println("Read File : ", v1.path);

                processFile(splitArr[1], untaint v1.path);

                log:printInfo("Moving file ..........");

                string destPath2 = moveFile(v1);

                // Moving the file to another location on the same ftp server after processing.
                error? renameErr = ftpClient->rename(v1.path, destPath2);
            }
        }

        foreach string v2 in m.deletedFiles {
            log:printInfo("Deleted file path: " + v2);
        }
    }
}

// Processing logic that needs to be done on the file content based on the file type.
public function processFile(string ext, string source) {
    log:printInfo("Started processing the file ");

    if (ext == "xml") {
        var getResult = ftpClient->get(source);

        log:printInfo("Reading xml fileeee");
        if (getResult is io:ReadableByteChannel) {
            io:ReadableCharacterChannel? characters = new io:ReadableCharacterChannel(getResult, "utf-8");
            if (characters is io:ReadableCharacterChannel) {
                var result = characters.readXml();
                if (result is xml) {
                    io:println("File content: ", result);
                } else {
                    io:println("An error occured.", result);
                    return;
                }
                var closeResult = characters.close();
            }
        } else {
            io:println("An error occured.", getResult);
            return;
        }
    }
}


// Generating the file name of the processed file.
public function moveFile(ftp:FileInfo v2) returns string {
    log:printInfo("Generating dest path");
    int subString = v2.path.lastIndexOf("/");
    int length = v2.path.length();
    string subPath = v2.path.substring((subString + 1), length);
    string destPath = "/movedFolder" + "/" + subPath;
    log:printInfo("Completed generating dest path");

    return destPath;
}

public function removePrefix(ftp:FileInfo v2) returns string[] {
    log:printInfo("Removing prefix of the file name");

    string[] splitArr = v2.path.split("\\.");
    log:printInfo("Removing prefix of the file name completed");
    return splitArr;    
}

public function splitFilePattern(string filePattrn) returns string[] {
    log:printInfo("Splitting file Pattern");

    string[] splitFileName = filePattrn.split("\\.");
    log:printInfo("Splitting of file name completed");
    return splitFileName;
}