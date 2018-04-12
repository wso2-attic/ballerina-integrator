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

package data_backed_service;

import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/mime;
import ballerina/http;
import ballerina/config;
import ballerina/io;
//import ballerinax/docker;
//import ballerinax/kubernetes;

type Employee {
    string name;
    int age;
    int ssn;
    int employeeId;
<<<<<<< HEAD
};
=======
}
>>>>>>> 705a07328106a5462d4f87e3c6889840681b6720

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host:"localhost",
    port:3306,
    name:"EMPLOYEE_RECORDS",
    username:"root",
    password:"qwe123",
    poolOptions:{maximumPoolSize:5}
};

<<<<<<< HEAD
endpoint http:Listener listener {
    port:9090
};

=======
>>>>>>> 705a07328106a5462d4f87e3c6889840681b6720
//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"employee_database_service",
//    tag:"v1.0"
//}

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
//    name:"ballerina-guides-employee-database-service"
//}

endpoint http:ServiceEndpoint listener {
    port:9090
};

@http:ServiceConfig {
    basePath:"/records"
}
service<http:Service> employee_data_service bind listener {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/employee/"
    }
    addEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        // Extract the data from the request payload
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData = check <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            //return;
        }

        // Invoke insertData function to save data in the Mymysql database
        json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn, employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/employee/{employeeId}"
    }
    retrieveEmployeeResource(endpoint httpConnection, http:Request request, string employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
                // Invoke retrieveById function to retrieve data from Mymysql database
                var employeeData = retrieveById(empID);
                // Send the response back to the client with the employee data
                response.setJsonPayload(employeeData);
                _ = httpConnection -> respond(response);
            }
            error err => {
                //Check path parameter errors and send bad request message to client
                response.setStringPayload("Error : Please enter a valid employee ID ");
                response.statusCode = 400;
                _ = httpConnection -> respond(response);
            }
        }
    }

    @http:ResourceConfig {
        methods:["PUT"],
        path:"/employee/"
    }
    updateEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData = check <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            //return;
        }

        // Invoke updateData function to update data in Mymysql database
        json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn, employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/employee/{employeeId}"
    }
    deleteEmployeeResource(endpoint httpConnection, http:Request request, string employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
                // Invoke deleteData function to delete the data from Mymysql database
                var deleteStatus = deleteData(empID);
                // Send the response back to the client with the employee data
                response.setJsonPayload(deleteStatus);
                _ = httpConnection -> respond(response);
            }
            error err => {
                //Check path parameter errors and send bad request message to client
                response.setStringPayload("Error : Please enter a valid employee ID ");
                response.statusCode = 400;
                _ = httpConnection -> respond(response);
            }
        }
    }
}

public function insertData(string name, int age, int ssn, int employeeId) returns (json) {

    json updateStatus;
    // Prepare the mysql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_VARCHAR, name, sql:DIRECTION_IN);
    sql:Parameter para2 = (sql:TYPE_INTEGER, age, sql:DIRECTION_IN);
    sql:Parameter para3 = (sql:TYPE_INTEGER, ssn, sql:DIRECTION_IN);
    sql:Parameter para4 = (sql:TYPE_INTEGER, employeeId, sql:DIRECTION_IN);
    string sqlString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, para1, para2, para3, para4);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Inserted Successfully"};
        }
        error err => {
            updateStatus = {"Status":"Data Not Inserted", "Error":err.message};
        }
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_INTEGER, employeeID, sql:DIRECTION_IN);
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select action defined in ballerina sql connector
    table dataTable = check employeeDB -> select(sqlString, null, para1);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue = check <json>dataTable;
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, int employeeId) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_VARCHAR, name, sql:DIRECTION_IN);
    sql:Parameter para2 = (sql:TYPE_INTEGER, age, sql:DIRECTION_IN);
    sql:Parameter para3 = (sql:TYPE_INTEGER, ssn, sql:DIRECTION_IN);
    sql:Parameter para4 = (sql:TYPE_INTEGER, employeeId, sql:DIRECTION_IN);
    string sqlString = "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, para1, para2, para3, para4);
    match ret {
        int updateRowCount => {
            if (updateRowCount > 0) {
                updateStatus = {"Status":"Data Updated Successfully"};
            }
            else {
                updateStatus = {"Status":"Data Not Updated"};
            }
        }
        error err => {
            updateStatus = {"Status":"Data Not Updated", "Error":err.message};
        }
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_INTEGER, employeeID, sql:DIRECTION_IN);
    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, para1);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Deleted Successfully"};
        }
        error err => {
            updateStatus = {"Status":"Data Not Deleted", "Error":err.message};
        }
    }
    return updateStatus;
}
