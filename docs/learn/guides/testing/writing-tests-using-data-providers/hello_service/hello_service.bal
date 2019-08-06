// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

// This hello_service will be up and running in port 9090. 
service hello on new http:Listener(9090) {
    resource function sayHello(http:Caller caller, http:Request req) {
        //get the payload sent by user and assign it to the variable payload.
        var payload = req.getTextPayload();

        string userInput = "";
        if (payload is string) {
            // Modify the payload
            userInput = "Hello " +untaint payload + "";
        } else {
            userInput = "Payload is empty ";
        }
        // The modified payload is sent back to the client as the response. 
        var result = caller->respond(userInput);

        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}