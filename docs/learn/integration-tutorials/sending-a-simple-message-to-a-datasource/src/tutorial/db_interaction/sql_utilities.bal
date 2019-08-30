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
import ballerina/io;
import ballerinax/java.jdbc;

// This function returns the output from the SELECT Query when a doctor's speciality is given as the input
public function getDoctorDetails(string speciality) returns json|error {

    json jsonReturnValue = {};

    var ret = testDB->select(QUERY_SELECT_DOCTOR_INFORMATION, (), speciality);

    if (ret is table< record {}>) {
        var jsonConvertRet = json.constructFrom(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = {"Status": "Data Not Found", "Error":"Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    } else {
        jsonReturnValue = {"Status": "Data Not Found","Error": "Error occurred in data retrieval" };
        log:printError("Error occurred in data retrieval", err = ret);
    }
    return jsonReturnValue;
}

// This function returns the output from the INSERT Query when the fields of the request payload is given 
// as the input
public function addDoctorDetails(string name, string hospital, string speciality, string availability, int charge)
                                                                                returns jdbc:UpdateResult|error {

    jdbc:UpdateResult|error result = testDB->update(QUERY_INSERT_DOCTOR_INFORMATION, name, hospital, speciality,
                                                                                        availability, charge);
    var response = handleTransaction(result);
    return response;
}

// This function returns the output from the UPDATE Query when the fields of the request payload is given
// as the input
public function updateDoctorDetails(string name, string hospital, string speciality, string availability, int charge)
                                                                                returns jdbc:UpdateResult|error {

    jdbc:UpdateResult|error result = testDB->update(QUERY_UPDATE_DOCTOR_INFORMATION, hospital, speciality,
                                                                                    availability, charge, name);
    var response = handleTransaction(result);
    return response;
}

// This function returns the output from the DELETE Query when the name of the doctor whose records
// to be removed is given as the input
public function deleteDoctorDetails(string name) returns jdbc:UpdateResult|error {

    jdbc:UpdateResult|error result = testDB->update(QUERY_DELETE_DOCTOR_INFORMATION, name);
    var response = handleTransaction(result);
    return response;
}

// This function returns and logs whether the query status when the result from the query is given as input
function handleTransaction(jdbc:UpdateResult|error result) returns jdbc:UpdateResult|error{
    if (result is jdbc:UpdateResult) {
            if (result.updatedRowCount > 0) {
                log:printInfo("Query execution successful");
            } else {
                log:printError("Query execution failed");
            }
    } else {
            log:printError("Error occurred in query execution", err = result);
    }
        return result;
}

