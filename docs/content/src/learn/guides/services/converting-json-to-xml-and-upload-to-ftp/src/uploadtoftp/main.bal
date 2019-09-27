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
import ballerina/xmlutils;
import wso2/ftp;
import ballerina/log;

const string remoteLocation = "/home/in/employees.xml";

ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("ftp.host"),
    port: config:getAsInt("ftp.port"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("ftp.username"),
            password: config:getAsString("ftp.password")
        }
    }
};
ftp:Client ftp = new(ftpConfig);

@http:ServiceConfig {
    basePath: "company"
}
service company on new http:Listener(8080) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/employees"
    }
    resource function addEmployees(http:Caller caller, http:Request request) returns error? {
        http:Response response = new();
        json jsonPayload = check request.getJsonPayload();
        xml|error employee = xmlutils:fromJSON(jsonPayload);
        if (employee is xml) {
            var ftpResult = ftp->put(remoteLocation, employee);
            if (ftpResult is error) {
                log:printError("Error", ftpResult);
                response.setJsonPayload({Message: "Error occurred uploading file to FTP.", Resason: ftpResult.reason()});
            } else {
                response.setJsonPayload({Message: "Employee records uploaded successfully."});
            }
        } else {
            response.setJsonPayload({Message: "Error occurred tranforming json to xml.", Resason: employee.reason()});
        }
        var httpResult = caller->respond(response); 
    }
}
