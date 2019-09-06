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

listener http:Listener backendListener = new http:Listener(config:getAsInt("BACKEND_PORT"));

@http:ServiceConfig {
    basePath: "/arithmeticService"
}
service arithmeticService on backendListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/add"
    }
    resource function add(http:Caller caller, http:Request request) {

        var requestPayload = request.getJsonPayload();
        http:Response response = new;

        if(requestPayload is json) {
            int valOne = <int>requestPayload.valueOne;
            int valTwo = <int>requestPayload.valueTwo;
            int result = valOne + valTwo;
            map<json> responseJson= {"result":result};
            response.statusCode = http:STATUS_OK;
            response.setJsonPayload(<@untainted> responseJson);
        }
        else{
            response.statusCode = http:STATUS_BAD_REQUEST;
            map<json> errorPayload = {"error":"Invalid request payload"};
            response.setJsonPayload(errorPayload);
        }
        var res = caller->respond(response);
        handleResponseError(res);
        return;
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/subtract"
    }
    resource function subtract(http:Caller caller, http:Request request) {

        var requestPayload = request.getJsonPayload();
        http:Response response = new;

        if(requestPayload is json) {
            int valOne = <int>requestPayload.valueOne;
            int valTwo = <int>requestPayload.valueTwo;
            int result = valOne - valTwo;
            map<json> responseJson= {"result":result};
            response.statusCode = http:STATUS_OK;
            response.setJsonPayload(<@untainted> responseJson);
        }
        else{
            response.statusCode = http:STATUS_BAD_REQUEST;
            map<json> errorPayload = {"error":"Invalid request payload"};
            response.setJsonPayload(errorPayload);
        }
        var res = caller->respond(response);
        handleResponseError(res);
        return;
    }
}

function handleResponseError(error? response) {
    if (response is error) {
        log:printError("Error sending response", err = response);
    }
}
