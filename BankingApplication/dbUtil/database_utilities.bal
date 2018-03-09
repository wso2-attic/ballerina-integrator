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

import ballerina.config;
import ballerina.data.sql;

// Function to get SQL database client connector
public function getDatabaseClientConnector () (sql:ClientConnector sqlConnector) {
    // DB configurations - Get configuration details from the ballerina.config file
    string dbHost = config:getGlobalValue("DATABASE_HOST");
    string dbUsername = config:getGlobalValue("DATABASE_USERNAME");
    string dbPassword = config:getGlobalValue("DATABASE_PASSWORD");
    var dbPort, conversionError1 = <int>config:getGlobalValue("DATABASE_PORT");
    // If string to int conversion fails, throw the error
    if (conversionError1 != null) {
        throw conversionError1;
    }
    var dbMaxPoolSize, conversionError2 = <int>config:getGlobalValue("DATABASE_MAX_POOL_SIZE");
    // If string to int conversion fails, throw the error
    if (conversionError2 != null) {
        throw conversionError2;
    }

    // Construct connection URL
    string connectionUrl = "jdbc:mysql://" + dbHost + ":" + dbPort + "?useSSL=true";
    // Create SQL connector
    sqlConnector = create sql:ClientConnector(sql:DB.GENERIC, "", 0, "", dbUsername, dbPassword,
                                              {url:connectionUrl, maximumPoolSize:dbMaxPoolSize});
    // Return the SQL client connector
    return;
}

// Function to create a database
public function createDatabase (sql:ClientConnector sqlConnector, string dbName) (int updateStatus) {
    endpoint<sql:ClientConnector> databaseEP {
        sqlConnector;
    }
    // Execute the create database SQL query
    updateStatus = databaseEP.update("CREATE DATABASE IF NOT EXISTS " + dbName, null);
    // Return the update status
    return;
}
