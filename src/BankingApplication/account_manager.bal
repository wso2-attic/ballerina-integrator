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

import ballerina/config;
import ballerina/log;
import ballerina/data.sql;

endpoint sql:Client bankDB {
    database:sql:DB.MYSQL,
    host:"localhost",
    port:3306,
    name:"bankDB?useSSL=false",
    username:"root",
    password:"Mathematics",
    options:{maximumPoolSize:5}
};

// Function to add users to 'ACCOUNT' table of 'bankDB' database
public function createAccount (string name) returns (int) {
    // SQL query parameters
    sql:Parameter username = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter initialBalance = {sqlType:sql:Type.INTEGER, value:0};
    sql:Parameter[] parameters = [username, initialBalance];
    // Insert query
    _ = bankDB -> update("INSERT INTO ACCOUNT (USERNAME, BALANCE) VALUES (?, ?)", parameters);
    // Get the primary key of the last insertion (Auto incremented value)
    table dt =? bankDB -> select("SELECT LAST_INSERT_ID() AS ACCOUNT_ID", null, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult =? <json>dt;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    int accId =? <int>jsonResult[0]["ACCOUNT_ID"].toString();
    log:printInfo("Account ID for user: '" + name + "': " + accId);
    // Return the primary key, which will be the account number of the account
    return accId;
}

// Function to verify an account whether it exists or not
public function verifyAccount (int accId) returns (boolean) {
    log:printInfo("Verifying whether account ID " + accId + " exists");
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter[] parameters = [id];
    // Select query to check whether account exists
    table dt =? bankDB -> select("SELECT COUNT(*) AS COUNT FROM ACCOUNT WHERE ID = ?", parameters, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult =? <json>dt;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    var count =? <int>jsonResult[0]["COUNT"].toString();
    // Return a boolean, which will be true if account exists; false otherwise
    return <boolean>count;
}

// Function to check balance in an account
public function checkBalance (int accId) returns (int|error) {
    // Verify account whether it exists and return an error if not
    if (!verifyAccount(accId)) {
        error err = {message:"Error: Account does not exist"};
        return err;
    }
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter[] parameters = [id];
    // Select query to get balance
    table dt =? bankDB -> select("SELECT BALANCE FROM ACCOUNT WHERE ID = ?", parameters, null);
    // convert the table to json - Failure will not happen in this case; Hence omitting the error handling
    var jsonResult =? <json>dt;
    // convert the json to int - Failure will not happen in this case; Hence omitting the error handling
    int balance =? <int>jsonResult[0]["BALANCE"].toString();
    log:printInfo("Available balance in account ID " + accId + ": " + balance);
    // Return the balance
    return balance;
}

// Function to deposit money to an account
public function depositMoney (int accId, int amount) returns (error|null) {
    // Check whether the amount specified is valid and return an error if not
    if (amount <= 0) {
        error err = {message:"Error: Invalid amount"};
        return err;
    }
    if (!verifyAccount(accId)) {
        // Verify account whether it exists and return an error if not
        error err = {message:"Error: Account does not exist"};
        return err;
    }
    log:printInfo("Depositing money to account ID: " + accId);
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter depositAmount = {sqlType:sql:Type.INTEGER, value:amount};
    sql:Parameter[] parameters = [depositAmount, id];
    // Update query to increase the current balance
    _ = bankDB -> update("UPDATE ACCOUNT SET BALANCE = (BALANCE + ?) WHERE ID = ?", parameters);
    log:printInfo("$" + amount + " has been deposited to account ID " + accId);
    return null;
}

// Function to withdraw money from an account
public function withdrawMoney (int accId, int amount) returns (error|null) {
    // Check whether the amount specified is valid and return an error if not
    if (amount <= 0) {
        error err = {message:"Error: Invalid amount"};
        return err;
    }
    // Check current balance
    match checkBalance(accId) {
        error checkBalanceError => return checkBalanceError;
        int balance => {
        // Check whether the user has enough money to withdraw the requested amount and return an error if not
            if (balance < amount) {
                error err = {message:"Error: Not enough balance"};
                return err;
            }
        }
    }
    log:printInfo("Withdrawing money from account ID: " + accId);
    // SQL query parameters
    sql:Parameter id = {sqlType:sql:Type.INTEGER, value:accId};
    sql:Parameter withdrawAmount = {sqlType:sql:Type.INTEGER, value:amount};
    sql:Parameter[] parameters = [withdrawAmount, id];
    // Update query to reduce the current balance
    _ = bankDB -> update("UPDATE ACCOUNT SET BALANCE = (BALANCE - ?) WHERE ID = ?", parameters);
    log:printInfo("$" + amount + " has been withdrawn from account ID " + accId);
    return null;
}

// Function to transfer money from one account to another
public function transferMoney (int fromAccId, int toAccId, int amount) returns (boolean) {
    boolean isSuccessful;
    // Transaction block - Ensures the 'ACID' properties
    // Withdraw and deposit should happen as a transaction when transfer money from one account to another
    transaction with retries= 0 {
        log:printInfo("Initiating transaction");
        // Withdraw money from transferor's account
        match withdrawMoney(fromAccId, amount) {
            error withdrawError => {
                log:printError("Error while withdrawing the money: " + withdrawError.message);
                // Abort transaction if withdrawal fails
                log:printInfo("Transaction aborted");
                log:printError("Failed to transfer money from account ID " + fromAccId + " to account ID " + toAccId);
                abort;
            }
            null => {
                match depositMoney(toAccId, amount) {
                    error depositError => {
                        log:printError("Error while depositing the money: " + depositError.message);
                        // Abort transaction if deposit fails
                        log:printInfo("Transaction aborted");
                        log:printError("Failed to transfer money from account ID " + fromAccId + " to account ID " +
                                       toAccId);
                        abort;
                    }
                    null => isSuccessful = true;
                }
            }
        }
        // If transaction successful
        log:printInfo("Transaction committed");
        log:printInfo("Successfully transferred $" + amount + " from account ID " + fromAccId + " to account ID " +
                      toAccId);
    }
    return isSuccessful;
}
