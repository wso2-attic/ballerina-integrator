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
import ballerina/config;
import wso2/ftp;

ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USER"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};
ftp:Client ftpClient = new (ftpConfig);

json[] employees = [];

@http:ServiceConfig {
    basePath: "/organization"
}
service employeeDetails on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employees"
    }
    resource function getEmployees(http:Caller caller, http:Request req) {

        fork {
            worker w1 returns io:ReadableByteChannel {
                return checkpanic ftpClient->get("/home/ftp-user/in/employees1.csv");
            }
            worker w2 returns io:ReadableByteChannel {
                return checkpanic ftpClient->get("/home/ftp-user/in/employees2.csv");
            }
        }
        record {io:ReadableByteChannel w1; io:ReadableByteChannel w2;} results = wait {w1, w2};
        populateEmp(results.w1);
        populateEmp(results.w2);
        http:Response response = new;
        response.setJsonPayload(<@untainted>employees);
        error? respond = caller->respond(response);
    }
}

//populating the employees json array with employee rows
function populateEmp(io:ReadableByteChannel ch) {
    string[][] employeeRows = convertToStringArray(ch);
    foreach var i in 1 ... employeeRows.length() - 1 {
        json m = convertToJson(employeeRows[i]);
        employees[employees.length()] = <@untainted>m;
    }
}

//extracting a string array of arrays from a ReadableByteChannel
function convertToStringArray(io:ReadableByteChannel rbChannel) returns @tainted string[][] {
    io:ReadableCharacterChannel characters = new (rbChannel, "utf-8");
    io:ReadableCSVChannel csvChannel = new (characters);
    string[][] rows = [];
    while (csvChannel.hasNext()) {
        string[] currentRow = <string[]> checkpanic csvChannel.getNext();
        rows[rows.length()] = currentRow;
    }
    var closeResult = characters.close();
    return rows;
}

//converting a string array to required json format
function convertToJson(string[] empRow) returns json {
    json emp = {
        "empId": empRow[0],
        "firstName": empRow[1],
        "lastName": empRow[2],
        "joinedDate": empRow[3]
    };
    return emp;
}
