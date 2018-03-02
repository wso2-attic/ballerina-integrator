package BankingApplication.dbUtil;

import ballerina.data.sql;
import ballerina.test;

// Unit test for testing getDatabaseClientConnector() function
function testGetDatabaseClientConnector () {
    // Get database client connector
    sql:ClientConnector sqlConnector = getDatabaseClientConnector();
    // 'sqlConnector' should not be null
    test:assertTrue(sqlConnector != null, "Cannot obtain database client connector");
}

// Unit test for testing createDatabase() function
function testCreateDatabase () {
    // Get database client connector
    sql:ClientConnector sqlConnector = getDatabaseClientConnector();
    // Create database "testDB"
    int status = createDatabase(sqlConnector, "testDB");
    // 'status' should be 1
    test:assertTrue(status == 1, "Cannot execute the 'create database' query properly");
}
