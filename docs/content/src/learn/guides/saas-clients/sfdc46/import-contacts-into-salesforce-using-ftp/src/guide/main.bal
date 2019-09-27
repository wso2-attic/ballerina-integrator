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
import ballerina/lang.'string as strings;
import wso2/ftp;
import wso2/sfdc46;

// Salesforce configuration.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("SF_BASE_URL"),
    clientConfig: {
        accessToken: config:getAsString("SF_ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("SF_CLIENT_ID"),
            clientSecret: config:getAsString("SF_CLIENT_SECRET"),
            refreshToken: config:getAsString("SF_REFRESH_TOKEN"),
            refreshUrl: config:getAsString("SF_REFRESH_URL")
        }
    }
};

// FTP listener configuration.
listener ftp:Listener remoteServer = new ({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    port: config:getAsInt("FTP_PORT"),
    path: config:getAsString("FTP_PATH"),
    pollingInterval: config:getAsInt("FTP_POLLING_INTERVAL"),
    fileNamePattern: "(.*).csv"
});

// FTP client configuration.
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

// Create FTP client.
ftp:Client ftpClient = new (ftpConfig);
// Create salesforce client.
sfdc46:Client salesforceClient = new (sfConfig);
// Create salesforce bulk client.
sfdc46:SalesforceBulkClient sfBulkClient = salesforceClient->createSalesforceBulkClient();

service ftpServerConnector on remoteServer {
    resource function fileResource(ftp:WatchEvent m) returns error? {
        // Create CSV insert operator.
        sfdc46:CsvInsertOperator csvInserter = check sfBulkClient->createCsvInsertOperator("Contact");

        foreach ftp:FileInfo v1 in m.addedFiles {
            log:printInfo("CSV file added to the FTP location: " + v1.path);
            (string | error)? fileContent = getFileContent(v1.path);

            if (fileContent is string) {
                // Import csv contacts to Salesforce.
                sfdc46:BatchInfo batch = check csvInserter->insert(<@untainted> fileContent);
                // Getting the results of the import.
                sfdc46:Result[] batchResult = check csvInserter->getResult(batch.id, config:getAsInt("SF_NO_OF_RETRIES"));

                if (checkBatchResults(batchResult)) {
                    log:printInfo("Imported contacts successfully!");
                } else {
                    log:printError("Errors in imported contacts!");
                }
            } else {
                log:printError("Error occurred while getting file comtent from FTP", fileContent);
            }
        }
    }
}

// Check whether batch results are successful or not.
function checkBatchResults(sfdc46:Result[] results) returns boolean {
    foreach sfdc46:Result res in results {
        if (!res.success) {
            log:printError("Failed result, res=" + res.toString(), err = ());
            return false;
        }
    }
    return true;
}

// Read content of a remote file.
function getFileContent(string path) returns @tainted string | error? {
    io:ReadableByteChannel | error rbc = ftpClient->get(path);

    if (rbc is io:ReadableByteChannel) {
        // Read content.
        byte[] readContent;
        string textContent = "";

        while (true) {
            byte[] | io:Error result = rbc.read(1000);

            if (result is io:EofError) {
                break;
            } else if (result is io:Error) {
                log:printError("Error occurred while reading the csv file, file: " + path, err = result);
                return;
            } else {
                readContent = result;
                string | error readContentStr = strings:fromBytes(readContent);

                if (readContentStr is string) {
                    textContent = textContent + readContentStr;
                } else {
                    log:printError("Error occurred while converting readContent byte array to string.",
                    err = readContentStr);
                    return;
                }
            }
        }
        // close channel.
        error? close = rbc.close();
        if (close is error) {
            log:printError("Error occurred while closing ReadableByteChannel", close);
        }
        return textContent;
    } else {
        log:printError("Error occured in retrieving content.", rbc);
        return;
    }
}
