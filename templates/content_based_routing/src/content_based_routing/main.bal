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
import ballerina/log;
import ballerina/config;

const string ADD_OPERATION = "add";
const string SUBTRACT_OPERATION = "subtract";

listener http:Listener clientListener = new http:Listener(config:getAsInt("LISTENER_PORT"));
http:Client arithmeticServiceEP = new(config:getAsString("CLIENT_ENDPOINT"));

@http:ServiceConfig {
    basePath: "/calculatorService"
}
service calculatorService on clientListener {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/calculate"
    }
    resource function calculate(http:Caller caller, http:Request request) {

        http:Response|error response;
        http:Response errorResponse = new;

        var requestPayload = request.getJsonPayload();

        if(requestPayload is json) {
            string operation = <string>requestPayload.operation;

            match operation {
                ADD_OPERATION => {
                    response = arithmeticServiceEP->post("/add", <@untainted> request);
                    handleResponse(caller, response);
                    return;
                }
                SUBTRACT_OPERATION => {
                    response = arithmeticServiceEP->post("/subtract", <@untainted> request);
                    handleResponse(caller, response);
                    return;
                }
                _ => {
                    errorResponse.statusCode = http:STATUS_BAD_REQUEST;
                    errorResponse.setJsonPayload({"error":"Operation not found"});
                    var resp = caller->respond(errorResponse);
                    handleError(resp);
                    return;
                }
            }
        } else {
            errorResponse.statusCode = http:STATUS_BAD_REQUEST;
            map<json> errorPayload = {"error":"Invalid request payload"};
            errorResponse.setJsonPayload(errorPayload);
            error? res = caller->respond(errorResponse);
            handleError(res);
            return;
        }
    }
}

function handleResponse(http:Caller caller, http:Response|error response) {
    if(response is http:Response) {
        var res = caller->respond(response);
        handleError(res);
        return;
    } else {
        handleError(response);
        return;
    }
}

function handleError(error? response) {
    if (response is error) {
        log:printError("Error sending response", err = response);
    }
}
