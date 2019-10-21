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

import ballerina/http;
import ballerina/io;
import ballerina/test;

http:Client clientEP = new("http://localhost:9090/spreadsheets");
string spreadsheetName = "firstSpreadsheet";
string worksheetName = "firstWorksheet";
json testSpreadsheet = {};
int worksheetId = 0;
json[][] entries = [["Name", "Score"], ["Keetz", "12"], ["Niro", "78"], ["Nisha", "98"], ["Kana", "86"]];
string topLeftCell = "A1";
string column = "A";
string bottomRightCell = "B5";
int row = 2;
string cellValue = "Test Value";

# Test function

@test:Config{}
function testCreateSpreadsheet() {
    var response = clientEP->post("/" + spreadsheetName, ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Failed to create the Spreadsheet!");
        var payload = response.getJsonPayload();
        if (payload is json) {
            testSpreadsheet = <@untainted> payload;
        } else {
            test:assertFail(msg = "Spreadsheet creation did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testCreateSpreadsheet"]
}
function testAddNewSheet() {
    var response = clientEP->post("/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName, ());
    if (response is http:Response) {
        var payload = response.getJsonPayload();
        test:assertEquals(response.statusCode, 201, msg = "Failed to add the worksheet!");
        if (payload is json) {
            worksheetId = payload.sheetId is json ? <@untainted> (<int>payload.sheetId) : 0;
        } else {
            test:assertFail(msg = "Worksheet creation did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testCreateSpreadsheet"]
}
function testOpenSpreadsheetById() {
    var response = clientEP->get("/" + io:sprintf("%s", testSpreadsheet.spreadsheetId), ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Failed to open the Spreadsheet!");
        var payload = response.getJsonPayload();
        if (!(payload is json)) {
            test:assertFail(msg = "Retrieval of spreadsheet info did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testAddNewSheet"]
}
function testSetSheetValues() {
    http:Request request = new;
    // Set the request payload.
    request.setJsonPayload(entries);
    var response = clientEP->put("/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName + "/"
                                 + topLeftCell + "/" + bottomRightCell, request);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Failed to add values into the worksheet!");
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "The entries have been added into the worksheet " + worksheetName,
                              msg = "Failed to add values into the worksheet!");
        } else {
            test:assertFail(msg = "Failed to add values into the worksheet.");
        }
    }
}

@test:Config{
    dependsOn: ["testSetSheetValues"]
}
function testGetSheetValues() {
    var response = clientEP->get("/worksheet/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName
                                 + "/" + topLeftCell + "/" + bottomRightCell, ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Failed to retrieve values from the worksheet!");
        var payload = response.getJsonPayload();
        if (payload is json) {
            test:assertEquals(payload, entries, msg = "Failed to retrieve values from the worksheet!");
        } else {
            test:assertFail(msg = "Retrieval of worksheet values did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testSetSheetValues"]
}
function testGetColumnData() {
    var response = clientEP->get("/column/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName
                                 + "/" + column, ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Failed to retrieve column values from the worksheet!");
        var payload = response.getJsonPayload();
        if (payload is json) {
            json[] columnValues = [];
            int counter = 0;
            foreach var entry in entries {
                columnValues[counter] = entries[counter][0];
                counter += 1;
            }
            test:assertEquals(payload, columnValues, msg = "Failed to retrieve column values from the worksheet!");
        } else {
            test:assertFail(msg = "Retrieval of worksheet column values did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testSetSheetValues"]
}
function testGetRowData() {
    var response = clientEP->get("/row/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName
                                 + "/" + io:sprintf("%s", row), ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Failed to retrieve row values from the worksheet!");
        var payload = response.getJsonPayload();
        if (payload is json) {
            test:assertEquals(payload, entries[row - 1], msg = "Failed to retrieve row values from the worksheet!");
        } else {
            test:assertFail(msg = "Retrieval of worksheet row values did not return JSON object.");
        }
    }
}

@test:Config{
    dependsOn: ["testAddNewSheet", "testGetRowData"]
}
function testSetCellData() {
    http:Request request = new;
    // Set the request payload.
    request.setTextPayload(cellValue);
    var response = clientEP->put("/cell/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName + "/C"
                                 +"/" + io:sprintf("%s", row), request);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 201, msg = "Failed to add value into the cell!");
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, "The cell data has been added into the worksheet " + worksheetName,
                              msg = "Failed to add value into the cell!");
        } else {
            test:assertFail(msg = "Failed to add value into the cell.");
        }
    }
}

@test:Config{
    dependsOn: ["testSetCellData"]
}
function testGetCellData() {
    var response = clientEP->get("/cell/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/" + worksheetName + "/C"
                                 + "/" + io:sprintf("%s", row), ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Failed to retrieve cell value from the worksheet!");
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(payload, cellValue, msg = "Failed to retrieve cell value from the worksheet!");
        } else {
            test:assertFail(msg = "Retrieval of cell value did not return string value.");
        }
    }
}

@test:Config{
    dependsOn: ["testGetSheetValues", "testGetColumnData", "testGetRowData", "testGetCellData"]
}
function testDeleteSheet() {
    var response = clientEP->delete("/" + io:sprintf("%s", testSpreadsheet.spreadsheetId) + "/"
                                    + io:sprintf("%s", worksheetId), ());
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Failed to delete the worksheet!");
    }
}
