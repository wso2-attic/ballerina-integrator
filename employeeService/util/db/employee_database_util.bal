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

public function insertData (string name, string age, string ssn, string employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Inserted"};

    string sqlString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES ('" + name + "','" + age + "','" +
                       ssn + "','" + employeeId + "')";
    // Insert data to SQL database by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Inserted Successfully"};
    }
    return updateStatus;
}

public function updateData (string name, string age, string ssn, string employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Updated"};

    string sqlString = "UPDATE EMPLOYEES SET Name = '" + name + "', Age = '" + age + "', SSN = '" + ssn + "'WHERE
                        EmployeeID  = '" + employeeId + "'";
    // Update existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Updated Successfully"};
    }
    return updateStatus;
}

public function deleteData (string employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Deleted"};

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = '" + employeeID + "'";
    // Delete existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Deleted Successfully"};
    }
    return updateStatus;
}

public function retrieveById (string employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = '" + employeeID + "'";
    // Retrieve employee data by invoking call action defined in ballerina sql connector
    var dataTable = employeeDataBase.call(sqlString, null, null);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue, _ = <json>dataTable;
    return jsonReturnValue;
}