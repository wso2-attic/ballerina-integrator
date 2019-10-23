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

listener http:Listener OnlineShoppingEP = new(9090);
listener http:Listener LocalShopEP = new(9091);

//Defines a client endpoint for the local shop with online shop link.
http:Client clientEP = new("http://localhost:9091/LocalShop");

//This is a passthrough service.
service OnlineShopping on OnlineShoppingEP {
    //This resource allows all HTTP methods.
    @http:ResourceConfig {
        path: "/"
    }
    resource function passthrough(http:Caller caller, http:Request req) {
        log:printInfo("Request will be forwarded to Local Shop  .......");
        //'forward()' sends the incoming request unaltered to the backend. Forward function
        //uses the same HTTP method as in the incoming request.
        var clientResponse = clientEP->forward("/", req);
        if (clientResponse is http:Response) {
            //Sends the client response to the caller.
            var result = caller->respond(clientResponse);
            handleError(result);
        } else {
            //Sends the error response to the caller.
            http:Response res = new;
            res.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            res.setPayload(<string>clientResponse.detail()?.message);
            var result = caller->respond(res);
            handleError(result);
        }
    }
}

//Sample Local Shop service.
service LocalShop on LocalShopEP {
    //The LocalShop only accepts requests made using the specified HTTP methods.
    @http:ResourceConfig {
        methods: ["POST", "GET"],
        path: "/"
    }
    resource function helloResource(http:Caller caller, http:Request req) {
        log:printInfo("You have been successfully connected to local shop  .......");
        // Make the response for the request.
        http:Response res = new;
        res.setPayload("Welcome to Local Shop! Please put your order here.....");
        //Sends the response to the caller.
        var result = caller->respond(res);
        handleError(result);
    }
}

function handleError(error? result) {
    if (result is error) {
        log:printError(result.reason(), err = result);
    }
}
