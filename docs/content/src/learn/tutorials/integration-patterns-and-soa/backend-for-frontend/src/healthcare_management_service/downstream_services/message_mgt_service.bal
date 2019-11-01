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

@http:ServiceConfig {
    basePath: "/messageMgt"
}
service message_mgt_service on new http:Listener(9095) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/list"
    }
    resource function getMessages(http:Caller caller, http:Request req) {
        http:Response response = new;
        json messageResponse = [
        {
            "id": "NOT01",
            "name": "Lab Test Result Notification",
            "description": "Test Result of Glucose test is ready"
        },
        {
            "id": "NOT02",
            "name": "Flu Vaccine Status",
            "description": "Flu vaccines due for this year"
        }
        ];
        response.setJsonPayload(messageResponse);
        checkpanic caller->respond(response);
    }
}
