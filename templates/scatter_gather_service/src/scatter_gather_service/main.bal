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

http:Client EP1 = new (config:getAsString("ENDPOINT_1"));
http:Client EP2 = new (config:getAsString("ENDPOINT_2"));

@http:ServiceConfig {
    basePath: "/endpoints"
}
service scatter_gather on new http:Listener(config:getAsInt("LISTENER_PORT")) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/call"
    }
    resource function callEps(http:Caller caller, http:Request req) {
        http:Client[] epArray = [];
        http:Response[] resArray = [];

        epArray.push(EP1);
        epArray.push(EP2);

        
        var requestPayload = req.getJsonPayload();
        if (requestPayload is json) {

            http:Request epRequest = new;
            epRequest.setJsonPayload(<@untainted> requestPayload);

            foreach http:Client EP in epArray {
                http:Response | error epResponse = EP->post("", epRequest);
                if (epResponse is http:Response) {
                    resArray.push(epResponse);
                } else {
                    log:printError("Endpoint " + EP.url + " did not respond with a valid http response", epResponse);
                }
            }

            json aggregatedResult = {};

            foreach http:Response response in resArray {
                    json | error payload = response.getJsonPayload();
                    if (payload is json) {
                        json | error mergedPayload = aggregatedResult.mergeJson(payload);
                        if (mergedPayload is json) {
                            aggregatedResult = mergedPayload;

                        }
                    } else {
                    log:printError("Response payload from a backend is not Json", payload);
                    }
                }        

            http:Response responseToClient = new;
            responseToClient.setJsonPayload(<@untainted> aggregatedResult);
            respondToClient(caller, responseToClient);
        } else {
            respondToClient(caller, createErrorResponse(400, "Not a valid Json request payload"));
        }
    }
}

//util method to respond to a caller and handle error
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}

// util method to create error response
function createErrorResponse(int statusCode, string msg) returns http:Response {
    http:Response errorResponse = new;
    errorResponse.statusCode = statusCode;
    errorResponse.setPayload(msg);
    return errorResponse;
} 
