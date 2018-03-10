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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

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
