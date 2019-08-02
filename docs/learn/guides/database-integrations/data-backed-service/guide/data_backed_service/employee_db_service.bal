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

import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import ballerina/sql;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "employee_database_service",
//    tag: "v1.0",
//    baseImage: "ballerina/ballerina:<BALLERINA_VERSION>"
//}
//
//@docker:CopyFiles{
//    files: [{ source: <path_to_JDBC_jar>,
//            target: "/ballerina/runtime/bre/lib" }]
//}
//
//@docker:Expose{}

//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "ballerina-guides-employee-database-service",
//    path: "/"
//}
//
//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "ballerina-guides-employee-database-service"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/employee_database_service:v1.0",
//    baseImage: "ballerina/ballerina:<BALLERINA_VERSION>",
//    name: "ballerina-guides-employee-database-service",
//    copyFiles: [{ target: "/ballerina/runtime/bre/lib",
//                source: <path_to_JDBC_jar> }]
//}

listener http:Listener httpListener = new(9090);

type Employee record {
    string name;
    int age;
    int ssn;
    int employeeId;
};

// Create SQL client for MySQL database
mysql:Client employeeDB = new({
        host: config:getAsString("DATABASE_HOST", defaultValue = "localhost"),
        port: config:getAsInt("DATABASE_PORT", defaultValue = 3306),
        name: config:getAsString("DATABASE_NAME", defaultValue = "EMPLOYEE_RECORDS"),
        username: config:getAsString("DATABASE_USERNAME", defaultValue = "root"),
        password: config:getAsString("DATABASE_PASSWORD", defaultValue = "root"),
        dbOptions: { useSSL: false }
    });

// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service EmployeeData on httpListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/employee/"
    }
    resource function addEmployeeResource(http:Caller httpCaller, http:Request request) {
        // Initialize an empty http response message
        http:Response response = new;

        // Extract the data from the request payload
        var payloadJson = request.getJsonPayload();

        if (payloadJson is json) {
            Employee|error employeeData = Employee.convert(payloadJson);

            if (employeeData is Employee) {
                // Validate JSON payload
                if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
                    employeeData.employeeId == 0) {
                    response.setPayload("Error : json payload should contain
                    {name:<string>, age:<int>, ssn:<123456>, employeeId:<int>}");
                    response.statusCode = 400;
                } else {
                    // Invoke insertData function to save data in the MySQL database
                    json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn,
                        employeeData.employeeId);
                    // Send the response back to the client with the employee data
                    response.setPayload(ret);
                }
            } else {
                // Send an error response in case of a conversion failure
                response.statusCode = 400;
                response.setPayload("Error: Please send the JSON payload in the correct format");
            }
        } else {
            // Send an error response in case of an error in retriving the request payload
            response.statusCode = 500;
            response.setPayload("Error: An internal error occurred");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employee/{employeeId}"
    }
    resource function retrieveEmployeeResource(http:Caller httpCaller, http:Request request, string
        employeeId) {
        // Initialize an empty http response message
        http:Response response = new;
        // Convert the employeeId string to integer
        var empID = int.convert(employeeId);
        if (empID is int) {
            // Invoke retrieveById function to retrieve data from Mymysql database
            var employeeData = retrieveById(empID);
            // Send the response back to the client with the employee data
            response.setPayload(untaint employeeData);
        } else {
            response.statusCode = 400;
            response.setPayload("Error: employeeId parameter should be a valid integer");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/employee/"
    }
    resource function updateEmployeeResource(http:Caller httpCaller, http:Request request) {
        // Initialize an empty http response message
        http:Response response = new;

        // Extract the data from the request payload
        var payloadJson = request.getJsonPayload();
        if (payloadJson is json) {
            Employee|error employeeData = Employee.convert(payloadJson);

            if (employeeData is Employee) {
                if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
                    employeeData.employeeId == 0) {
                    response.setPayload("Error : json payload should contain
                        {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
                    response.statusCode = 400;
                } else {
                    // Invoke updateData function to update data in mysql database
                    json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn,
                        employeeData.employeeId);
                    // Send the response back to the client with the employee data
                    response.setPayload(ret);
                }
            } else {
                // Send an error response in case of a conversion failure
                response.statusCode = 400;
                response.setPayload("Error: Please send the JSON payload in the correct format");
            }
        } else {
            // Send an error response in case of an error in retriving the request payload
            response.statusCode = 500;
            response.setPayload("Error: An internal error occurred");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/employee/{employeeId}"
    }
    resource function deleteEmployeeResource(http:Caller httpCaller, http:Request request, string
        employeeId) {
        // Initialize an empty http response message
        http:Response response = new;
        // Convert the employeeId string to integer
        var empID = int.convert(employeeId);
        if (empID is int) {
            var deleteStatus = deleteData(empID);
            // Send the response back to the client with the employee data
            response.setPayload(deleteStatus);
        } else {
            response.statusCode = 400;
            response.setPayload("Error: employeeId parameter should be a valid integer");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }
}

public function insertData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus;
    string sqlString =
    "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    // Check type to verify the validity of the result from database
    if (ret is sql:UpdateResult) {
        updateStatus = { "Status": "Data Inserted Successfully" };
    } else {
        updateStatus = { "Status": "Data Not Inserted", "Error": "Error occurred in data update" };
        // Log the error for the service maintainers.
        log:printError("Error occurred in data update", err = ret);
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {
    json jsonReturnValue = {};
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select remote function defined in ballerina sql client
    var ret = employeeDB->select(sqlString, (), employeeID);
    if (ret is table<record {}>) {
        // Convert the sql data table into JSON using type conversion
        var jsonConvertRet = json.convert(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    } else {
        jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data retrieval" };
        log:printError("Error occurred in data retrieval", err = ret);
    }
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus;
    string sqlString =
    "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update remote function defined in ballerina sql client
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    if (ret is sql:UpdateResult) {
        if (ret.updatedRowCount > 0) {
            updateStatus = { "Status": "Data Updated Successfully" };
        } else {
            updateStatus = { "Status": "Data Not Updated" };
        }
    } else {
        updateStatus = { "Status": "Data Not Updated",  "Error": "Error occurred during update operation" };
        // Log the error for the service maintainers.
        log:printError("Error occurred during update operation", err = ret);
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    json updateStatus;

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update remote function defined in ballerina sql client
    var ret = employeeDB->update(sqlString, employeeID);
    if (ret is sql:UpdateResult) {
        updateStatus = { "Status": "Data Deleted Successfully" };
    } else {
        updateStatus = { "Status": "Data Not Deleted",  "Error": "Error occurred during delete operation" };
        // Log the error for the service maintainers.
        log:printError("Error occurred during delete operation", err = ret);
    }
    return updateStatus;
}

