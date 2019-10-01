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

@http:ServiceConfig {
    basePath: "reservation"
}
service reservation on new http:Listener(8081) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createAppointment"
    }
    resource function createAppointment(http:Caller caller, http:Request request) {
        json responsePayload = {
            "appointmentId": "1001",
            "patient_name": "Thomas Colins",
            "date": "30-09-2019",
            "time": "3.00pm",
            "doctor_name": "John Doe",
            "fee": "1000.00"
        };
        http:Response response = new ();
        response.setJsonPayload(responsePayload);
        error? respond = caller->respond(response);
    }
}

