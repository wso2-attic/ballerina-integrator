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

http:Client abcEP = new("http://localhost:8081/abc/quote");
http:Client xyzEP = new("http://localhost:8082/xyz/quote");

@http:ServiceConfig {
    basePath: "/stocktrading"
}
service stockQuote on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/stockquote"
    }
    resource function getQuote(http:Caller caller, http:Request req) returns error?{
        var company = req.getQueryParamValue("company");
        http:Response response = new;
        match company {
            "abc" => {
                response = checkpanic abcEP->get("/");
            }
            "xyz" => {
                response = checkpanic xyzEP->get("/");
            }
            _ => {
                response.statusCode = http:STATUS_BAD_REQUEST;
                response.setTextPayload("No matching company found.");
            }
        }        
        error? respond = caller->respond(response);
    }    
}
