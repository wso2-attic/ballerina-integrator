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

import ballerina/log;
import ballerina/http;
import wso2/messageStore;

// CODE-SEGMENT-BEGIN: segment_1
messageStore:MessageStoreConfiguration messageStoreConfig = {
    messageBroker: "ACTIVE_MQ",
    providerUrl: "tcp://localhost:61616",
    queueName: "myStore",
    retryConfig: storeRetryConfig
};

messageStore:MessageStoreRetryConfig storeRetryConfig = {
    count: 4,
    interval: 2000,
    backOffFactor: 1.5,
    maxWaitInterval: 15000
};

messageStore:MessageStoreConfiguration failOverMessageStoreConfig = {
    messageBroker: "ACTIVE_MQ",
    providerUrl: "tcp://localhost:61616",
    queueName: "myFailoverStore"
};

// Create storing endpoints
messageStore:Client failoverStoreClient = checkpanic new messageStore:Client(failOverMessageStoreConfig);
messageStore:Client storeClient = checkpanic new messageStore:Client(messageStoreConfig, failoverStore = failoverStoreClient);
// CODE-SEGMENT-END: segment_1

// CODE-SEGMENT-BEGIN: segment_2
// Store message and respond to the client with 202 status code
@http:ServiceConfig { basePath: "/hospitalMgtService" }
service hospitalMgtService on new http:Listener(9092) {
    // HTTP resource listening for messages
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"],
        path: "/categories/{category}/reserve"
    }
    resource function scheduleAppointment(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var payload = request.getJsonPayload();
        var result = storeClient->store(request);
        if (result is error) {
            // Handle error occured during storing message
            response.statusCode = http:INTERNAL_SERVER_ERROR_500;
            response.setJsonPayload({
                "Message": "Error while storing the message on JMS broker"
            });
            check caller->respond(response);
            return;
        } else {
            // Respond with 202 status code
            response.statusCode = http:ACCEPTED_202;
            check caller->respond(response);
            return;
        }
    }
}
// CODE-SEGMENT-END: segment_2