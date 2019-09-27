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
import ballerina/http;
import ballerina/jsonutils;
import ballerina/log;
import ballerinax/java.jdbc;

jdbc:Client employeeDB = new ({
    url: config:getAsString("MYSQL_URL"),
    username: config:getAsString("MYSQL_USERNAME"),
    password: config:getAsString("MYSQL_PASSWORD"),
    dbOptions: {useSSL: false}
});

listener http:Listener employeeEP = new (9095);

@http:ServiceConfig {
    basePath: "/staff"
}

service dbTransactions on employeeEP {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employee/{lastName}"
    }

    resource function getEmployees(http:Caller caller, http:Request request, string lastName) {
        http:Response response = new;
        log:printInfo("The select operation - Select data from a table");
        var selectResult = employeeDB->select("SELECT firstName FROM Employee WHERE lastName = ?", (), lastName);

        if (selectResult is table<record {}>) {
            json jsonConversionResult = jsonutils:fromTable(selectResult);
            log:printInfo(jsonConversionResult.toString());
            response.statusCode = http:STATUS_OK;
            response.setJsonPayload(jsonConversionResult);
        } else {
            log:printError("Error occurred in querying data");
            response.statusCode = http:STATUS_NOT_FOUND;
            json responseJson = {"Failed": selectResult.reason()};
            response.setJsonPayload(<@untainted>responseJson);
        }

        var result = caller->respond(response);

        if (result is error) {
            log:printError("Error sending response to the client", err = result);
        }
    }
}

