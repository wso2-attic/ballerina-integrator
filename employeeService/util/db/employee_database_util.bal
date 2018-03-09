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

package employeeService.util.db;

import ballerina.data.sql;

sql:ClientConnector sqlConnection;

public function initializeDatabase (string dbHost, string dbPort, string userName, string password, string dbName)
(boolean) {
    // Convert dbPort string to integer value
    var dbPortNumber, _ = <int>dbPort;
    dbName = dbName + "?useSSL=false";
    try {
        // Initialize the global variable "sqlConnection" with MySQL database connection
        sqlConnection = create sql:ClientConnector(sql:DB.MYSQL, dbHost, dbPortNumber, dbName, userName, password,
                                                   {maximumPoolSize:5});
        // Create the employee database table by invoking createTable function
        _ = createTable();
    }
    catch (error err) {
        error initializationError = {msg:"Database Initialization Error. Please check the database: " + err.msg};
        throw initializationError;
    }
    return true;
}

public function createTable () (int) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Create table by invoking update action defined in ballerina sql connector
    string sqlString = "CREATE TABLE IF NOT EXISTS EMPLOYEES (EmployeeID INT, Name VARCHAR
                       (50), Age INT, SSN INT, PRIMARY KEY (EmployeeID))";
    int updateRowCount = employeeDataBase.update(sqlString, null);
    return updateRowCount;
}

public function insertData (string name, int age, int ssn, int employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Inserted"};
    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
    sql:Parameter para3 = {sqlType:sql:Type.INTEGER, value:ssn};
    sql:Parameter para4 = {sqlType:sql:Type.INTEGER, value:employeeId};
    sql:Parameter[] params = [para1, para2, para3, para4];
    string sqlString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, params);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Inserted Successfully"};
    }
    return updateStatus;
}

public function updateData (string name, int age, int ssn, int employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Updated"};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
    sql:Parameter para3 = {sqlType:sql:Type.INTEGER, value:ssn};
    sql:Parameter para4 = {sqlType:sql:Type.INTEGER, value:employeeId};
    sql:Parameter[] params = [para1, para2, para3, para4];
    string sqlString = "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, params);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Updated Successfully"};
    }
    return updateStatus;
}

public function deleteData (int employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Deleted"};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:employeeID};
    sql:Parameter[] params = [para1];
    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, params);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Deleted Successfully"};
    }
    return updateStatus;
}

public function retrieveById (int employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:employeeID};
    sql:Parameter[] params = [para1];
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking call action defined in ballerina sql connector
    var dataTable = employeeDataBase.call(sqlString, params, null);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue, _ = <json>dataTable;
    return jsonReturnValue;
}
