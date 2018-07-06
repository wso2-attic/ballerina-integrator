// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/http;
import ballerina/config;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"employee_database_service",
//    tag:"v1.0",
//    baseImage:"ballerina/ballerina-platform:0.975.0"
//}
//
//@docker:CopyFiles{
//    files:[{source:<path_to_JDBC_jar>,
//            target:"/ballerina/runtime/bre/lib"}]
//}
//
//@docker:Expose{}

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-employee-database-service",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-employee-database-service"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/employee_database_service:v1.0",
//    baseImage:"ballerina/ballerina-platform:0.975.0",
//    name:"ballerina-guides-employee-database-service",
//    copyFiles:[{target:"/ballerina/runtime/bre/lib",
//                source:<path_to_JDBC_jar>}]
//}

endpoint http:Listener listener {
    port: 9090
};

type Employee record {
    string name;
    int age;
    int ssn;
    int employeeId;
};

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host: config:getAsString("DATABASE_HOST", default = "localhost"),
    port: config:getAsInt("DATABASE_PORT", default = 3306),
    name: config:getAsString("DATABASE_NAME", default = "EMPLOYEE_RECORDS"),
    username: config:getAsString("DATABASE_USERNAME", default = "root"),
    password: config:getAsString("DATABASE_PASSWORD", default = ""),
    dbOptions: { useSSL: false }
};

// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service<http:Service> EmployeeData bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/employee/"
    }
    addEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        // Extract the data from the request payload
        var payloadJson = check request.getJsonPayload();
        employeeData = check <Employee>payloadJson;

        // check for errors with JSON payload using
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
            employeeData.employeeId == 0) {
            response.setTextPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection->respond(response);
            done;
        }

        // Invoke insertData function to save data in the Mymysql database
        json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn,
            employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employee/{employeeId}"
    }
    retrieveEmployeeResource(endpoint httpConnection, http:Request request, string
    employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        int empID = check <int>employeeId;
        // Invoke retrieveById function to retrieve data from Mymysql database
        var employeeData = retrieveById(empID);
        // Send the response back to the client with the employee data
        response.setJsonPayload(untaint employeeData);
        _ = httpConnection->respond(response);
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/employee/"
    }
    updateEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        // Extract the data from the request payload
        var payloadJson = check request.getJsonPayload();
        employeeData = check <Employee>payloadJson;

        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
            employeeData.employeeId == 0) {
            response.setTextPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection->respond(response);
            done;
        }

        // Invoke updateData function to update data in mysql database
        json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn,
            employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection->respond(response);
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/employee/{employeeId}"
    }
    deleteEmployeeResource(endpoint httpConnection, http:Request request, string
    employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var empID = check <int>employeeId;
        var deleteStatus = deleteData(empID);
        // Send the response back to the client with the employee data
        response.setJsonPayload(deleteStatus);
        _ = httpConnection->respond(response);
    }
}

public function insertData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus;
    string sqlString =
    "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    // Use match operator to check the validity of the result from database
    match ret {
        int updateRowCount => {
            updateStatus = { "Status": "Data Inserted Successfully" };
        }
        error err => {
            updateStatus = { "Status": "Data Not Inserted", "Error": err.message };
        }
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {
    json jsonReturnValue;
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select action defined in ballerina sql connector
    var ret = employeeDB->select(sqlString, (), employeeID);
    match ret {
        table dataTable => {
            // Convert the sql data table into JSON using type conversion
            jsonReturnValue = check <json>dataTable;
        }
        error err => {
            jsonReturnValue = { "Status": "Data Not Found", "Error": err.message };
        }
    }
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus = {};
    string sqlString =
    "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    match ret {
        int updateRowCount => {
            if (updateRowCount > 0) {
                updateStatus = { "Status": "Data Updated Successfully" };
            }
            else {
                updateStatus = { "Status": "Data Not Updated" };
            }
        }
        error err => {
            updateStatus = { "Status": "Data Not Updated", "Error": err.message };
        }
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    json updateStatus = {};

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB->update(sqlString, employeeID);
    match ret {
        int updateRowCount => {
            updateStatus = { "Status": "Data Deleted Successfully" };
        }
        error err => {
            updateStatus = { "Status": "Data Not Deleted", "Error": err.message };
        }
    }
    return updateStatus;
}
