package employeeService.util.db;

import ballerina.config;
import ballerina.data.sql;
import ballerina.test;

function beforeTest () {
    // Initialize the database before starting unit tests
    string dbHost = config:getGlobalValue("DATABASE_HOST");
    string dbPort = config:getGlobalValue("DATABASE_PORT");
    string userName = config:getGlobalValue("DATABASE_USERNAME");
    string password = config:getGlobalValue("DATABASE_PASSWORD");
    string dbName = config:getGlobalValue("DATABASE_NAME");

    _ = initializeDatabase(dbHost, dbPort, userName, password, dbName);
}

function afterTest () {
    // Clean up the database from the test entries
    _ = deleteData("111111111");
    _ = deleteData("222222222");
    _ = deleteData("333333333");
}

public function testCreateTable () {
    // Create a EMPLOYEE table in the database
    _ = createTable();
    // SQL query to check whether the table exists
    string sqlQueryString = "SHOW TABLES LIKE 'EMPLOYEES'";
    // Invoke the executeSqlQuery to execute SQL command
    var result = executeSqlQuery(sqlQueryString);
    // Assert EMPLOYEE table is at MySQL database
    test:assertTrue(result.hasNext(), "Error : Table not created");
}

public function testInsertData () {
    // Insert test employee to database using insertData function
    json jsonResponse = insertData("Test Case 1", "11", "111111111", "111111111");
    // Assert to check whether the function returns the status as success
    test:assertStringEquals(jsonResponse.Status.toString(), "Data Inserted Successfully", "insertData function failed");
    // Write a SQL query to retrieve the test employee that previous added
    string sqlQueryString = "SELECT * FROM EMPLOYEES WHERE Name = 'Test Case 1' AND Age = '11' AND SSN = '111111111'
                            AND EmployeeID = '111111111' LIMIT 1";
    // Invoke the executeSqlQuery to execute SQL command
    var result = executeSqlQuery(sqlQueryString);
    // Assert that the employee data is in the table
    test:assertTrue(result.hasNext(), "Cannot find test data in database");
}


public function testRetrieveById () {
    // Insert test employee to database using SQL command
    string sqlQueryString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES ('Test Case 2', '22',
                             '222222222', '222222222')";
    _ = executeSqlQuery(sqlQueryString);
    // Retrieve employee data from retrieveById function
    json employeeData = retrieveById("222222222");
    // Assert that the retrieved data matched with the stored employee data
    test:assertTrue(lengthof employeeData > 0, "retrieveById function failed");
    test:assertStringEquals(employeeData[0].Name.toString(), "Test Case 2", "retrieveById Name not matched");
    test:assertStringEquals(employeeData[0].Age.toString(), "22", "retrieveById Age not matched");
    test:assertStringEquals(employeeData[0].SSN.toString(), "222222222", "retrieveById SSN not matched");
}


public function testUpdateData () {
    // Insert test employee to database using SQL command
    string sqlQueryString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES ('Test Case 3', '33',
                            '333333333', '333333333')";
    _ = executeSqlQuery(sqlQueryString);
    // Update the employee details using updateData function
    json updateStatus = updateData("Updated Test", "99", "999999999", "333333333");
    // Test the return value of the updateData function is correct
    test:assertStringEquals(updateStatus.Status.toString(), "Data Updated Successfully", "updateData function failed");
    // Retrieve data directly from MySQL database
    sqlQueryString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = '333333333'";
    table result = executeSqlQuery(sqlQueryString);
    var jsonResult, _ = <json>result;
    // Test whether the employee data in MySQL are updated
    test:assertStringEquals(jsonResult[0].Name.toString(), "Updated Test", "Updated Name not matched");
    test:assertStringEquals(jsonResult[0].Age.toString(), "99", "Updated  Age not matched");
    test:assertStringEquals(jsonResult[0].SSN.toString(), "999999999", "Updated  SSN not matched");
}

public function testDeleteData () {
    // Insert test employee to database using SQL command
    string sqlQueryString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES ('Test Case 4', '44',
                            '444444444', '444444444')";
    _ = executeSqlQuery(sqlQueryString);
    // Delete employee data using deleteData function
    json updateStatus = deleteData("444444444");
    // Check the return value of the function is correct
    test:assertStringEquals(updateStatus.Status.toString(), "Data Deleted Successfully", "deleteData function failed");
}

function executeSqlQuery (string sqlQueryString) (table) {
    endpoint<sql:ClientConnector> employeeDataBase {
    //get the initialized sqlConnection of the util.db package
        sqlConnection;
    }
    // call the MySQL database using sql connector
    var sqlReturnValue = employeeDataBase.call(sqlQueryString, null, null);
    return sqlReturnValue;
}