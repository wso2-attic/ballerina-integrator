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
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function asyncInvocations(http:Caller caller, http:Request req) {
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
        if (response1 is http:Response) {
            var payload = response1.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrieve the payload");
            }
            // Add the response from Endpoint A to responseJson variable.
            responseJson["A"] = responseStr;
        } else {
            string errorMsg = <string>response1.detail()?.message;
            log:printError(errorMsg);
            responseJson["A"] = errorMsg;
        }

        var response2 = wait f2;
        if (response2 is http:Response) {
            var payload = response2.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrieve the payload");
            }
            // Add the response from Endpoint B to responseJson variable.
            responseJson["B"] = responseStr;
        } else {
            string errorMsg = <string>response2.detail()?.message;
            log:printError(errorMsg);
            responseJson["B"] = errorMsg;
        }

        var response3 = wait f3;
        if (response3 is http:Response) {
            var payload = response3.getTextPayload();
            if (payload is string) {
                responseStr = payload;
            } else {
                log:printError("Failed to retrieve the payload");
            }
            // Add the response from Endpoint C to responseJson variable.
            responseJson["C"] = responseStr;
        } else {
            string errorMsg = <string>response3.detail()?.message;
            log:printError(errorMsg);
            responseJson["C"] = errorMsg;
        }

        // Send the response back to the client
        finalResponse.setJsonPayload(<@untainted>responseJson);
        log:printInfo(" >> Response : " + responseJson.toString());
        var result = caller->respond(finalResponse);
        if (result is error) {
            log:printError("Error sending response", result);
        }
    }
}
