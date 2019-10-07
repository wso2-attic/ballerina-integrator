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

http:Client grandOakHospital = new("http://localhost:9091/grandOak");
http:Client pineValleyHospital = new("http://localhost:9092/pineValley");

@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcare on new http:Listener(9090) {

    @http:ResourceConfig {
        path: "/doctor/{doctorType}"
    }
    resource function getDoctors(http:Caller caller, http:Request request, string doctorType) returns error? {
        json grandOakDoctors = {};
        json pineValleyDoctors = {};
        var grandOakResponse = grandOakHospital->get("/doctors/" + doctorType);
        var pineValleyResponse = pineValleyHospital->post("/doctors", {doctorType: doctorType});
        // Extract doctors array from grand oak hospital response
        if (grandOakResponse is http:Response) {
            json result = check grandOakResponse.getJsonPayload();
            grandOakDoctors = check result.doctors.doctor;
        } else {
            handleError(caller, <@untained> grandOakResponse.reason());
        }
        // Extract doctors array from pine valley hospital response
        if (pineValleyResponse is http:Response) {
            json result = check pineValleyResponse.getJsonPayload();
            pineValleyDoctors = check result.doctors.doctor;
        } else {
            handleError(caller, <@untained> pineValleyResponse.reason());
        }
        // Aggregate grand oak hospital's doctors with pine valley hospital's doctors
        if (grandOakDoctors is json[] && pineValleyDoctors is json[]) {
            foreach var item in pineValleyDoctors {
                grandOakDoctors.push(item);
            }
        }
        // Respond back to the caller with aggregated json response
        http:Response response = new();
        response.setJsonPayload(<@untained> grandOakDoctors);
        var result = caller->respond(response);

        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}

function handleError(http:Caller caller, string errorMsg) {
    http:Response response = new;

    json responsePayload = {
        "error": {
            "message": errorMsg
        }
    };
    response.setJsonPayload(responsePayload, "application/json");
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error sending response", err = result);
    }
}
