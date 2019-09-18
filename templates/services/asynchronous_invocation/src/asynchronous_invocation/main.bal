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

// Attributes associated with the service endpoint are defined here.
listener http:Listener asyncService = new (9090);

// By default Ballerina assumes that the service is to be exposed via HTTP/1.1.
@http:ServiceConfig {
    basePath: "/asyncInvocation"
}
service AsyncInvoker on asyncService {

    # Resource for the GET requests of mock backend service.
    #
    # + caller - Represents the remote client's endpoint.
    # + req - Represents the client request.
    # + return - If an error occurs it is returned to the user.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function asyncInvocations(http:Caller caller, http:Request req) returns error? {
        // Endpoint for the mock backend service.
        http:Client mockServiceEP = new ("http://localhost:9080");
        http:Response finalResponse = new;
        string responseStr = "";

        log:printInfo(" >> Invoking services asynchronously...");
        // 'start' allows you to invoke functions asynchronously.
        // Following three remote invocations returns without waiting for response.

        // Calling the backend to get the response from Endpoint A asynchronously.
        future<http:Response | error> f1 = start mockServiceEP->get("/endpoint-a");
        log:printInfo(" >> Invocation completed for Endpoint A, proceeding without blocking for a response.");

        // Calling the backend to get the response from Endpoint B asynchronously.
        future<http:Response | error> f2 = start mockServiceEP->get("/endpoint-b");
        log:printInfo(" >> Invocation completed for Endpoint B, proceeding without blocking for a response.");

        // Calling the backend to get the response from Endpoint C asynchronously.
        future<http:Response | error> f3 = start mockServiceEP->get("/endpoint-c");
        log:printInfo(" >> Invocation completed Endpoint C, proceeding without blocking for a response.");

        // Initialize an empty map<json> to add results from the backend call.
        map<json> responseJson = {};

        // `wait` blocks until the previously started async functions return.
        // Appends the responses of all 3 mock backend calls.
        var response1 = wait f1;
        // Add the response from Endpoint A to responseJson variable.
        if (response1 is http:Response) {
            responseJson["A"] = getPayload(response1);
        } else {
            responseJson["A"] = handleError(response1);
        }

        var response2 = wait f2;
        // Add the response from Endpoint B to responseJson variable.
        if (response2 is http:Response) {
            responseJson["B"] = getPayload(response2);
        } else {
            responseJson["B"] = handleError(response2);
        }

        var response3 = wait f3;
        // Add the response from Endpoint C to responseJson variable.
        if (response3 is http:Response) {
            responseJson["C"] = getPayload(response3);
        } else {
            responseJson["C"] = handleError(response3);
        }

        // Send the response back to the client
        finalResponse.setJsonPayload(<@untainted>responseJson);
        log:printInfo(" >> Response : " + responseJson.toString());
        var result = check caller->respond(finalResponse);
    }
}

function getPayload(http:Response response) returns string? {
    var payload = response.getTextPayload();
    if (payload is string) {
        return <@untained>payload;
    } else {
        log:printError("Failed to retrieve the payload");
    }
}

function handleError(error response) returns string {
    string errorMsg = <string>response.detail()?.message;
    log:printError(errorMsg);
    return errorMsg;
}
