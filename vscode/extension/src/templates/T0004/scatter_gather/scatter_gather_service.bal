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

listener http:Listener serviceEP = new http:Listener(${listenerPort});
http:Client EP1 = new ("${clientEP1}");
http:Client EP2 = new ("${clientEP2}");
json requestPayload = ${requestPayload};
@http:ServiceConfig {
    basePath: "/endpoints"
}

service scatter_gather on serviceEP {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/call"
    }
    resource function callEps(http:Caller caller, http:Request req) {
        http:Client[] epArray = [];
        http:Response[] resArray = [];

        epArray.push(EP1);
        epArray.push(EP2);

        http:Request epRequest = new;
        epRequest.setJsonPayload(requestPayload);

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
        responseToClient.setJsonPayload(aggregatedResult);
        respondToClient(caller, responseToClient);
    }
}

//util method to respond to a caller and handle error
function respondToClient(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error responding to client!", err = result);
    }
}
