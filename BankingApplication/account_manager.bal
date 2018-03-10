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

package BankingApplication;

import ballerina.config;
import ballerina.log;
import ballerina.data.sql;
import BankingApplication.dbUtil;

// Get the SQL client connector
sql:ClientConnector sqlConnector = dbUtil:getDatabaseClientConnector();

// Execute the database initialization function
boolean init = initializeDB();

// Function to add users to 'ACCOUNT' table of 'bankDB' database
public function createAccount (string name) (int accId) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    // SQL query parameters
    sql:Parameter username = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter initialBalance = {sqlType:sql:Type.INTEGER, value:0};
    sql:Parameter[] parameters = [username, initialBalance];
    // Insert query
    int rowsAffected = bankDB.update("INSERT INTO ACCOUNT (USERNAME, BALANCE) VALUES (?, ?)", parameters);
    log:printInfo("Creating account for user: '" + name + "'; Rows affected in ACCOUNT table: " + rowsAffected);
    // Get the primary key of the last insertion (Auto incremented value)
    table result = bankDB.select("SELECT LAST_INSERT_ID() AS ACCOUNT_ID", null, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult, _ = <json>result;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    accId, _ = (int)jsonResult[0]["ACCOUNT_ID"];
    log:printInfo("Account ID for user: '" + name + "': " + accId);
    // Return the primary key, which will be the account number of the account
    return;
}

// Function to verify an account whether it exists or not
public function verifyAccount (int accId) (boolean accExists) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    log:printInfo("Verifying whether account ID " + accId + " exists");
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter[] parameters = [id];
    // Select query to check whether account exists
    table result = bankDB.select("SELECT COUNT(*) AS COUNT FROM ACCOUNT WHERE ID = ?", parameters, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult, _ = <json>result;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    var count, _ = (int)jsonResult[0]["COUNT"];
    // Convert int to boolean
    accExists = <boolean>count;
    // Return a boolean, which will be true if account exists; false otherwise
    return;
}

// Function to check balance in an account
public function checkBalance (int accId) (int balance, error err) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    log:printInfo("Checking balance for account ID: " + accId);
    // Verify account whether it exists and return an error if not
    if (!verifyAccount(accId)) {
        err = {message:"Error: Account does not exist"};
        return;
    }
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter[] parameters = [id];
    // Select query to get balance
    table result = bankDB.select("SELECT BALANCE FROM ACCOUNT WHERE ID = ?", parameters, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult, _ = <json>result;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    balance, _ = (int)jsonResult[0]["BALANCE"];
    log:printInfo("Available balance in account ID " + accId + ": " + balance);
    // Return the balance
    return;
}

// Function to deposit money to an account
public function depositMoney (int accId, int amount) (error err) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    log:printInfo("Depositing money to account ID: " + accId);
    // Check whether the amount specified is valid and return an error if not
    if (amount <= 0) {
        err = {message:"Error: Invalid amount"};
        return;
    }
    // Verify account whether it exists and return an error if not
    if (!verifyAccount(accId)) {
        err = {message:"Error: Account does not exist"};
        return;
    }
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter depositAmount = {sqlType:sql:Type.INTEGER, value:amount};
    sql:Parameter[] parameters = [depositAmount, id];
    // Update query to increase the current balance
    int rowsAffected = bankDB.update("UPDATE ACCOUNT SET BALANCE = (BALANCE + ?) WHERE ID = ?", parameters);
    log:printInfo("Updating balance for account ID: " + accId + "; Rows affected in ACCOUNT table: " + rowsAffected);
    log:printInfo("$" + amount + " has been deposited to account ID " + accId);
    return;
}

// Function to withdraw money from an account
public function withdrawMoney (int accId, int amount) (error err) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    // Check whether the amount specified is valid and return an error if not
    log:printInfo("Withdrawing money from account ID: " + accId);
    if (amount <= 0) {
        err = {message:"Error: Invalid amount"};
        return;
    }
    // Check current balance
    var balance, checkBalanceError = checkBalance(accId);
    if (checkBalanceError != null) {
        err = checkBalanceError;
        return;
    }
    // Check whether the user has enough money to withdraw the requested amount and return an error if not
    if (balance < amount) {
        err = {message:"Error: Not enough balance"};
        return;
    }
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter withdrawAmount = {sqlType:sql:Type.INTEGER, value:amount};
    sql:Parameter[] parameters = [withdrawAmount, id];
    // Update query to reduce the current balance
    int rowsAffected = bankDB.update("UPDATE ACCOUNT SET BALANCE = (BALANCE - ?) WHERE ID = ?", parameters);
    log:printInfo("Updating balance for account ID: " + accId + "; Rows affected in ACCOUNT table: " + rowsAffected);
    log:printInfo("$" + amount + " has been withdrawn from account ID " + accId);
    return;
}

// Function to transfer money from one account to another
public function transferMoney (int fromAccId, int toAccId, int amount) (boolean isSuccessful) {
    // Transaction block - Ensures the 'ACID' properties
    // Withdraw and deposit should happen as a transaction when transfer money from one account to another
    transaction with retries(0) {
        log:printInfo("Initiating transaction");
        log:printInfo("Transferring money from account ID " + fromAccId + " to account ID " + toAccId);
        // Withdraw money from transferor's account
        error withdrawError = withdrawMoney(fromAccId, amount);
        if (withdrawError != null) {
            log:printError("Error while withdrawing the money: " + withdrawError.message);
            // Abort transaction if withdrawal fails
            abort;
        }
        // Deposit money to transferee's account
        error depositError = depositMoney(toAccId, amount);
        if (depositError != null) {
            log:printError("Error while depositing the money: " + depositError.message);
            // Abort transaction if deposit fails
            abort;
        }
        // If transaction successful
        isSuccessful = true;
        log:printInfo("Transaction committed");
        log:printInfo("Successfully transferred $" + amount + " from account ID " + fromAccId + " to account ID " +
                      toAccId);
    } failed {
        // Executed when a transaction fails
        log:printError("Error while transferring money from account ID " + fromAccId + " to account ID " + toAccId);
        log:printError("Transaction failed");
    }
    // Return a boolean, which will be true if transaction is successful; false otherwise
    return;
}

// Private function to initialize the database
function initializeDB () (boolean isInitialized) {
    endpoint<sql:ClientConnector> bankDB {
        sqlConnector;
    }
    // Read database name from the ballerina.config file
    string dbName = config:getGlobalValue("DATABASE_NAME");
    // Create the database if not exists
    int updateStatus1 = dbUtil:createDatabase(sqlConnector, dbName);
    log:printInfo("------------------------------- DB Initialization -------------------------------");
    log:printInfo("Creating database '" + dbName + "' if not exists; Status: " + updateStatus1);
    // Use the database created
    int updateStatus2 = bankDB.update("USE " + dbName, null);
    log:printInfo("Selecting database: '" + dbName + "'; Status: " + updateStatus2);
    // Drop table 'ACCOUNT' if exists
    int updateStatus3 = bankDB.update("DROP TABLE IF EXISTS ACCOUNT", null);
    log:printInfo("Dropping table 'ACCOUNT' if exists; Status: " + updateStatus3);
    // Create 'ACCOUNT' table
    int updateStatus4 = bankDB.update("CREATE TABLE ACCOUNT(ID INT AUTO_INCREMENT, USERNAME VARCHAR(20) NOT NULL,
    BALANCE INT UNSIGNED NOT NULL, PRIMARY KEY (ID))", null);
    log:printInfo("Creating table 'ACCOUNT'; Status: " + updateStatus4 + "\n");

    if (updateStatus1 == 1 && updateStatus2 == 0 && updateStatus3 == 0 && updateStatus4 == 0) {
        isInitialized = true;
    }
    // Return a boolean, which will be true if the initialization is successful; false otherwise
    return;
}
