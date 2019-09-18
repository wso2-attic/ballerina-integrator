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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

// By default Ballerina assumes that the service is to be exposed via HTTP/1.1.
@http:ServiceConfig {
    basePath: "/parallelService"
}
service ParallelService on new http:Listener(9090) {

    # Resource for the GET requests of mock backend service.
    #
    # + caller - Represents the remote client's endpoint.
    # + req - Represents the client request.
    # + return - If an error occurs it is returned to the user.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function parallelService(http:Caller caller, http:Request req) returns error? {
        // HTTP Client for the Mock Backend Service A.
        http:Client mockServiceA = new ("http://localhost:9091/service-a");
        // HTTP Client for the Mock Backend Service B.
        http:Client mockServiceB = new ("http://localhost:9092/service-b");
        http:Response finalResponse = new;
        string responseStr = "";
        map<json> responseJson = {};

        fork {
            // Worker to communicate with Resource A of Service A.
            worker workerA returns http:Response? {
                var responseA = mockServiceA->get("/resource-a");
                if (responseA is http:Response) {
                    return responseA;
                }
            }
            // Worker to communicate with Resource B of Service A.
            worker workerB returns http:Response? {
                var responseB = mockServiceA->get("/resource-b");
                if (responseB is http:Response) {
                    return responseB;
                }
            }
        }
        // Wait for responses from all the workers running in parallel.
        record{
            http:Response? workerA;
            http:Response? workerB;
        } responsesServiceA = wait {workerA, workerB};

        fork {
            // Worker to communicate with Resource A of Service B.
            worker workerC returns http:Response? {
                var responseA = mockServiceB->get("/resource-a");
                if (responseA is http:Response) {
                    return responseA;
                }
            }
            // Worker to communicate with Resource B of Service B.
            worker workerD returns http:Response? {
                var responseB = mockServiceB->get("/resource-b");
                if (responseB is http:Response) {
                    return responseB;
                }
            }
        }
        // Wait for responses from all the workers running in parallel.
        record{
            http:Response? workerC;
            http:Response? workerD;
        } responsesServiceB = wait {workerC, workerD};

        http:Response responseA = <http:Response>responsesServiceA["workerA"];
        responseJson["WorkerA"] = responseA.getTextPayload().toString();

        http:Response responseB = <http:Response>responsesServiceA["workerB"];
        responseJson["WorkerB"] = responseB.getTextPayload().toString();

        http:Response responseC = <http:Response>responsesServiceB["workerC"];
        responseJson["WorkerC"] = responseC.getTextPayload().toString();

        http:Response responseD = <http:Response>responsesServiceB["workerD"];
        responseJson["WorkerD"] = responseD.getTextPayload().toString();

        // Send the response back to the client
        finalResponse.setJsonPayload(<@untainted>responseJson);
        log:printInfo(" >> Response : " + responseJson.toString());
        var result = check caller->respond(finalResponse);
    }
}
