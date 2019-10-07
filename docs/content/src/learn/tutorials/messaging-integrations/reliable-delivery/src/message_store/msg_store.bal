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
import wso2/storeforward;


@http:ServiceConfig { basePath: "/orders" }
service stockQuote on new http:Listener(8080) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/new-order"
    }
    resource function placeOrder(http:Caller caller, http:Request request) returns error? {
        log:printInfo("Received order request at message store");

        // Configure message store to publish stock orders
        storeforward:MessageStoreConfiguration storeConfig = {
            messageBroker: "ACTIVE_MQ",
            providerUrl: "tcp://localhost:61616",
            queueName: "item_orders"
        };

        // Initialize client to store the message
        storeforward:Client storeClient = check new storeforward:Client(storeConfig);
        var result = storeClient->store(request);

        // Respond back to the caller based on the result
        if (result is error) {
            check caller->respond("Stock order placement failed.");
        } else {
            check caller->respond("Stock order placed successfully.");
        }
    }
}
