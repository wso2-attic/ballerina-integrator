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

import ballerina/io;
import wso2/gsheets4;
import ballerina/time;
import ballerina/log;

gsheets4:SpreadsheetConfiguration spreadsheetConfig = {
    oAuthClientConfig: {
        accessToken: "ya29.Il-iB7D7dpG7DOQZr8XDwtBF0sfh4fGR4sNOr9h1oNUg5AaWxmVcyorlSoSP1cWegen3jSL_ncLbDW8Jt3kZD08KHKBqUmWfHcnJRC5u9AMZCi9EvtUO2fJyT9-1pGIGxw",
        refreshConfig: {
            clientId: "268927563255-1p0hub0eme9onjrsnsgqu62rs2q1g7hj.apps.googleusercontent.com",
            clientSecret: "4TD6dnEioECgWHIGlZq3vPfP",
            refreshUrl: "",
            refreshToken: "1/b3g9rf87g6QnorOQsV-12gak_vn_WzzTEFFQfYFO6hE"
        }
    }
};
gsheets4:Client spreadsheetClient = new(spreadsheetConfig);


public function main() {
    string csvFilePath = "src/backup_csv_files/resources/people.csv";
    string spreadSheetName = "People_Info";
    string sheetName = getCurrentDateName();
    string topLeftCell = "A1";

    io:ReadableCSVChannel|error readableCsvChannelOrError = io:openReadableCsvFile(csvFilePath);
    if (readableCsvChannelOrError is error) {
        log:printError("An error occurred opening the Readable CSV Channel: ", err = readableCsvChannelOrError);
        return;
    }
    io:ReadableCSVChannel readableCsvChannel = <io:ReadableCSVChannel>readableCsvChannelOrError;


    string[][] csvData = getCsvFromFile(readableCsvChannel);

    gsheets4:Spreadsheet spreadsheet = checkpanic spreadsheetClient->createSpreadsheet(spreadSheetName);

    string spreadsheetId = checkpanic <@untainted>spreadsheet.getSpreadsheetId();

    _ = checkpanic spreadsheetClient->addNewSheet(spreadsheetId, sheetName);

    // Backup CSV Data
    boolean successful = checkpanic spreadsheetClient->setSheetValues(spreadsheetId,
        sheetName, csvData, topLeftCell, findBottomRightCell(csvData));

    if (successful) {
        io:println("Successfully backedup the CSV file.");
    }

    closeReadableCSVChannel(readableCsvChannel);

    string[][] spreadsheetData = checkpanic spreadsheetClient->getSheetValues(spreadsheetId, sheetName, topLeftCell,
                                                findBottomRightCell(csvData));

    displaySpreadsheetData(spreadsheetData);
}

function displaySpreadsheetData(string[][] spreadsheetData) {
    io:println("**************** CSV Entries ****************");
    foreach var row in spreadsheetData {
        foreach var entry in row {
            io:print(entry, "\t");
        }
        io:print("\n");
    }
    io:println("*********************************************");
}

function getCurrentDateName() returns string {
    time:Time time = time:currentTime();
    int year = time:getYear(time);
    int month = time:getMonth(time);
    int day = time:getDay(time);
    return year.toString() + "_" + month.toString() + "_" + day.toString();
}

function getCsvFromFile(io:ReadableCSVChannel csvChannel) returns string[][] {
    string[][] csvData = [];
    while (csvChannel.hasNext()) {
        string[]|error? records = csvChannel.getNext();
        if (records is string[]) {
            csvData.push(records);
        } else {
            log:printError("Error occurred while reading the CSV channel: ", err = records);
        }
    }
    return csvData;
}

function findBottomRightCell(string[][] csvData) returns string {
    int rowCount = csvData.length();
    int columnCount = 0;
    if (rowCount > 0) {
        columnCount = csvData[0].length();
    }
    return convColNumToChars(columnCount) + rowCount.toString();
}

function closeReadableCSVChannel(io:ReadableCSVChannel csvChannel) {
    var result = csvChannel.close();
    if (result is error) {
        log:printError("Error occurred while closing the channel: ", err = result);
    }
}

function convColNumToChars(int columnNumber) returns string {
    if (columnNumber != 0) {
        return convColNumToChars((columnNumber - 1) / 26) + genAsciiChar(columnNumber % 26);
    } else {
        return "";
    }
}

function genAsciiChar(int charCode) returns string {
    string[] charSet = ["Z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
        "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y"];
    return charSet[charCode];
}