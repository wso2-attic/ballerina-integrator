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
import ballerina/http;
import ballerina/log;

import wso2/gsheets4;

// Constants for error codes and messages.
const string RESPOND_ERROR_MSG = "Error occurred while responding to client.";
const string INVALID_PAYLOAD_MSG = "Invalid request payload.";
const string SPREADSHEET_CREATION_ERROR_MSG = "Error while creating creating the spreadsheet.";
const string WORKSHEET_CREATION_ERROR_MSG = "Error while creating the worksheet.";
const string SPREADSHEET_RETRIEVAL_ERROR_MSG = "Error while retrieving the spreadsheet information.";
const string PAYLOAD_EXTRACTION_ERROR_MSG = "Error while extracting the payload from request.";
const string ENTRY_ADDITION_ERROR_MSG = "Error while adding the entries to the worksheet.";
const string WORKSHEET_RETRIEVAL_ERROR_MSG = "Error while retrieving the entries in the worksheet.";
const string COLUMN_DATA_RETRIEVAL_ERROR_MSG = "Error while retrieving the values in the column.";
const string ROW_DATA_RETRIEVAL_ERROR_MSG = "Error while retrieving the values in the row.";
const string CELL_DATA_ADDITION_ERROR_MSG = "Error while adding the value to the cell.";
const string CELL_DATA_RETRIEVAL_ERROR_MSG = "Error while retrieving the value of the cell.";
const string WORKSHEET_DELETION_ERROR_MSG = "Error while deleting the worksheet.";

gsheets4:SpreadsheetConfiguration spreadsheetConfig = {
    oAuthClientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshUrl: config:getAsString("REFRESH_URL"),
            refreshToken: config:getAsString("REFRESH_TOKEN")
        }
    }
};



gsheets4:Client spreadsheetClient = new(spreadsheetConfig);

@http:ServiceConfig {
    basePath: config:getAsString("BASE_PATH")
}
service spreadsheetService on new http:Listener(config:getAsInt("LISTENER_PORT")) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{spreadsheetName}"
    }
    // Function to create a new spreadsheet.
    resource function createSpreadsheet(http:Caller caller, http:Request request, string spreadsheetName) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke createSpreadsheet remote function from spreadsheetClient.
        var response = spreadsheetClient->createSpreadsheet(<@untainted> spreadsheetName);
        if (response is gsheets4:Spreadsheet) {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_CREATED;
            backendResponse.setJsonPayload(<@untainted> convertSpreadsheetToJSON(response),
                                           contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            SPREADSHEET_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{spreadsheetId}/{worksheetName}"
    }
    // Function to add new worksheet.
    resource function addNewSheet(http:Caller caller, http:Request request, string spreadsheetId,
                                 string worksheetName) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke addNewSheet remote function from spreadsheetClient.
        var response = spreadsheetClient->addNewSheet(<@untainted> spreadsheetId, <@untainted> worksheetName);
        if (response is gsheets4:Sheet) {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_CREATED;
            backendResponse.setJsonPayload(<@untainted> convertSheetPropertiesToJSON(response.properties),
                                           contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            WORKSHEET_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/{spreadsheetId}"
    }
    // Function to open spreadsheet.
    resource function openSpreadsheetById(http:Caller caller, http:Request request, string spreadsheetId) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke openSpreadsheetById remote function from spreadsheetClient.
        var response = spreadsheetClient->openSpreadsheetById(<@untainted> spreadsheetId);
        if (response is gsheets4:Spreadsheet) {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_OK;
            backendResponse.setJsonPayload(<@untainted> convertSpreadsheetToJSON(response),
                                           contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            SPREADSHEET_RETRIEVAL_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/{spreadsheetId}/{worksheetName}/{topLeftCell}/{bottomRightCell}"
    }
    // Function to add entries into an existing worksheet.
    resource function setSheetValues(http:Caller caller, http:Request request, string spreadsheetId,
                                     string worksheetName, string topLeftCell, string bottomRightCell) {
        // Define new response.
        http:Response backendResponse = new();
        // Extract the object content from request payload.
        string|string[][]|error entries = extractRequestContent(request);
        if (entries is string[][]) {
            // Invoke setSheetValues remote function from spreadsheetClient.
            var response = spreadsheetClient->setSheetValues(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                             <@untainted> entries, <@untainted> topLeftCell,
                                                             <@untainted> bottomRightCell);
            if (response == true) {
                // If the response is the boolean value 'true', send the success response.
                string payload = "The entries have been added into the worksheet " + worksheetName;
                backendResponse.statusCode = http:STATUS_CREATED;
                backendResponse.setTextPayload(payload, contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            } else {
                // Else, send the failure response.
                string payload = "Unable to add the entries into the worksheet " + worksheetName;
                backendResponse.statusCode = http:STATUS_BAD_REQUEST;
                backendResponse.setTextPayload(payload, contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, "Invalid content. String payload is expected by this method.",
                            INVALID_PAYLOAD_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/worksheet/{spreadsheetId}/{worksheetName}/{topLeftCell}/{bottomRightCell}"
    }
    // Function to retrieve worksheet entries.
    resource function getSheetValues(http:Caller caller, http:Request request, string spreadsheetId,
                                     string worksheetName, string topLeftCell, string bottomRightCell) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke getSheetValues remote function from spreadsheetClient.
        var response = spreadsheetClient->getSheetValues(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                         <@untainted> topLeftCell, <@untainted> bottomRightCell);
        if (response is error) {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            WORKSHEET_RETRIEVAL_ERROR_MSG);
        } else {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_OK;
            backendResponse.setJsonPayload(<@untainted> response, contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "column/{spreadsheetId}/{worksheetName}/{column}"
    }
    // Function to retrieve values in a column.
    resource function getColumnData(http:Caller caller, http:Request request, string spreadsheetId,
                                    string worksheetName, string column) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke getColumnData remote function from spreadsheetClient.
        var response = spreadsheetClient->getColumnData(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                        <@untainted> column);
        if (response is error) {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            COLUMN_DATA_RETRIEVAL_ERROR_MSG);
        } else {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_OK;
            backendResponse.setJsonPayload(<@untainted> response, contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/row/{spreadsheetId}/{worksheetName}/{row}"
    }
    // Function to retrieve values in a row.
    resource function getRowData(http:Caller caller, http:Request request, string spreadsheetId, string worksheetName,
                                 int row) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke getRowData remote function from spreadsheetClient.
        var response = spreadsheetClient->getRowData(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                     <@untainted> row);
        if (response is error) {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            ROW_DATA_RETRIEVAL_ERROR_MSG);
        } else {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_OK;
            backendResponse.setJsonPayload(<@untainted> response, contentType = "application/json");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/cell/{spreadsheetId}/{worksheetName}/{column}/{row}"
    }
    // Function to enter value into a cell.
    resource function setCellData(http:Caller caller, http:Request request, string spreadsheetId, string worksheetName,
                                  string column, int row) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke setCellData remote function from spreadsheetClient.
        string|string[][]|error cellValue = extractRequestContent(request);
        if (cellValue is string) {
        var response = spreadsheetClient->setCellData(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                      <@untainted> column, <@untainted> row, <@untainted> cellValue);
        if (response == true) {
            // If the response is the boolean value 'true', send the success response.
            string payload = "The cell data has been added into the worksheet " + worksheetName;
            backendResponse.statusCode = http:STATUS_CREATED;
            backendResponse.setTextPayload(payload, contentType = "text/plain");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Else, send the failure response.
            string payload = "Unable to enter the value into the cell in the worksheet" + worksheetName;
            backendResponse.statusCode = http:STATUS_BAD_REQUEST;
            backendResponse.setTextPayload(payload, contentType = "text/plain");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, "Invalid content. String payload is expected by this method.",
                            INVALID_PAYLOAD_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/cell/{spreadsheetId}/{worksheetName}/{column}/{row}"
    }
    // Function to retrieve value of a cell.
    resource function getCellData(http:Caller caller, http:Request request, string spreadsheetId, string worksheetName,
                                  string column, int row) {
        // Define new response.
        http:Response backendResponse = new();
        // Invoke getCellData remote function from spreadsheetClient.
        var response = spreadsheetClient->getCellData(<@untainted> spreadsheetId, <@untainted> worksheetName,
                                                      <@untainted> column, <@untainted> row);
        if (response is string) {
            // If there is no error, send the success response.
            backendResponse.statusCode = http:STATUS_OK;
            backendResponse.setTextPayload(<@untainted> response, contentType = "text/plain");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                            CELL_DATA_RETRIEVAL_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/{spreadsheetId}/{worksheetId}"
    }
    // Function to delete worksheet.
    resource function deleteSheet(http:Caller caller, http:Request request, string spreadsheetId, int worksheetId) {
        // Define new response.
        http:Response backendResponse = new();
        var response = spreadsheetClient->deleteSheet(spreadsheetId, worksheetId);
        if (response == true) {
            // If the response is the boolean value 'true', send the success response.
            string payload = "The worksheet " + io:sprintf("%s", worksheetId) + " has been deleted.";
            backendResponse.statusCode = http:STATUS_NO_CONTENT;
            backendResponse.setTextPayload(payload, contentType = "text/plain");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        } else {
            // Else, send the failure response.
            string payload = "Unable to delete the worksheet " + io:sprintf("%s", worksheetId);
            backendResponse.statusCode = http:STATUS_BAD_REQUEST;
            backendResponse.setTextPayload(payload, contentType = "text/plain");
            respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
        }
    }
}

// Function to extract the object content from request payload
function extractRequestContent(http:Request request) returns @tainted string|string[][]|error {
    string contentTypeStr = request.getContentType();
    if (equalsIgnoreCase(contentTypeStr, "application/json")) {
        var jsonObjectContent = request.getJsonPayload();
        if (jsonObjectContent is json[]) {
            string[][] stringMDArray = convertToStringMDArray(jsonObjectContent);
            return stringMDArray;
        } else {
            error err = error("Invalid payload content.", message = INVALID_PAYLOAD_MSG);
            return err;
        }
    } else if (equalsIgnoreCase(contentTypeStr, "text/plain")) {
        var textObjectContent = request.getTextPayload();
        if (textObjectContent is string) {
            return textObjectContent;
        } else {
            error err = error("Invalid payload content.",
                              message = <@untainted> <string>textObjectContent.detail()?.message);
            return err;
        }
    } else {
        error err = error("Invalid content. The payload should be 'application/json or text/plain'.'",
                          message = INVALID_PAYLOAD_MSG);
        return err;
    }
}

// Function to create the error response.
function createAndSendErrorResponse(http:Caller caller, string errorMessage, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code.
    response.statusCode = 500;
    //Set the error message to the error response payload.
    response.setPayload(<string> errorMessage);
    //log:printInfo("call respondAndHandleError func");
    respondAndHandleError(caller, response, respondErrorMsg);
}

// Function to send the response back to the client and handle the error.
function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    // Send response to the caller.
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}

function equalsIgnoreCase(string str1, string str2) returns boolean {
    if (str1.toUpperAscii() == str2.toUpperAscii()) {
        return true;
    } else {
        return false;
    }
}

function convertSpreadsheetToJSON(gsheets4:Spreadsheet spreadsheet) returns json {
    json jsonSpreadsheet = {
                                spreadsheetId: spreadsheet.spreadsheetId,
                                properties: io:sprintf("%s", spreadsheet.properties),
                                sheets: io:sprintf("%s", spreadsheet.sheets),
                                spreadsheetUrl: spreadsheet.spreadsheetUrl
                           };
    return jsonSpreadsheet;
}

function convertSheetPropertiesToJSON(gsheets4:SheetProperties sheetProperties) returns json {
    json jsonSheetProperties = {
                                   title: sheetProperties.title,
                                   sheetId: sheetProperties.sheetId,
                                   index: sheetProperties.index,
                                   sheetType: sheetProperties.sheetType,
                                   hidden: sheetProperties.hidden,
                                   rightToLeft: sheetProperties.rightToLeft,
                                   gridProperties: io:sprintf("%s", sheetProperties.gridProperties)
                               };
    return jsonSheetProperties;
}

function convertToStringMDArray(json[] jsonObjectContent) returns string[][] {
    string[][] stringArray = [];
    int i = 0;
    foreach var mainObj in jsonObjectContent {
        int j = 0;
        stringArray[i] = [];
        if (mainObj is json[]) {
            foreach var subObj in mainObj {
                stringArray[i][j] = <string>subObj;
                j += 1;
            }
            i += 1;
        }
    }
    return stringArray;
}
