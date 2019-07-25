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


messageStore:MessageStoreConfiguration secondaryMessageStoreConfig = {
    messageBroker: "ACTIVE_MQ",
    providerUrl: "tcp://localhost:61616",
    queueName: "myFailoverStore"
};
messageStore:Client secondaryStoreClient = checkpanic new messageStore:Client(secondaryMessageStoreConfig);

messageStore:MessageStoreRetryConfig storeRetryConfig = {
    count: 4,
    interval: 2000,
    backOffFactor: 1.5,
    maxWaitInterval: 15000
};

messageStore:MessageStoreConfiguration messageStoreConfig = {
    messageBroker: "ACTIVE_MQ",
    providerUrl: "tcp://localhost:61616",
    queueName: "myStore",
    retryConfig: storeRetryConfig,
    secondaryStore: secondaryStoreClient
};

messageStore:Client storeClient = checkpanic new messageStore:Client(messageStoreConfig);

// Export http listner port on 9091
listener http:Listener httpListener = new(9091);


// Service to store message and respond to client with 202
@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcareService on httpListener {
    // HTTP resource listening for messages
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"],
        path: "/appointment"
    }
    resource function make_appointment(http:Caller caller, http:Request request) returns error? {
        http:Response response = new;
        var payload = request.getJsonPayload();
        var result = storeClient->store(request);
        if (result is error) {
            // Hanlde error occured during storing message
            response.statusCode = http:INTERNAL_SERVER_ERROR_500;
            response.setJsonPayload({
                "Message": "Error while storing the message on JMS broker"
            });
            check caller->respond(response);
            return;
        } else {
            // Respond with 202
            response.statusCode = http:ACCEPTED_202;
            check caller->respond(response);
            return;
        }
    }
}


