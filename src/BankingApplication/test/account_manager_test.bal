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

import ballerina/test;

// Unit test for testing createAccount() function
@test:Config
function testCreateAccount () {
    string name = "Carol";
    // Create account for username "Carol"
    int accountId = createAccount(name);
    // 'AUTO_INCREMENT' starts from 1 and default value for int is 0 in Ballerina
    // Therefore, if account creation is successful then variable 'AccountId' should be greater than zero
    test:assertTrue(accountId > 0, msg="Failed to create account for user: " + name);
}

// Unit test for testing verifyAccount() function - passing scenario
@test:Config {
    dependsOn:["testCreateAccount"]
}
function testVerifyAccountPass () {
    // Create an account for username "Dave"
    int accountId = createAccount("Dave");
    // Provide an existing account ID to method 'verifyAccount()' - Account ID corresponding to username "Dave"
    boolean accountExists = verifyAccount(accountId);
    // Expected boolean value for variable 'accountExists' is true
    test:assertTrue(accountExists, msg="Method 'verifyAccount()' is not behaving as intended");
}

// Unit test for testing verifyAccount() function - failing scenario: due to invalid account
@test:Config
function testVerifyAccountFail () {
    // Provide a non existing account ID to method 'verifyAccount()'
    boolean accountExists = verifyAccount(1234);
    // Expected boolean value for variable 'accountExists' is false
    test:assertFalse(accountExists, msg="Method 'verifyAccount()' is not behaving as intended");
}

// Unit test for testing depositMoney() function - passing scenario
@test:Config {
    dependsOn:["testCreateAccount"]
}
function testDepositMoneyPass () {
    // Create an account for username "Elite"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Elite");
    // Deposit $500 to Elite's account
    match depositMoney(accountId, 500) {
        // Expected return value is null (not any errors) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless depositMoney function behaves erroneously
        error err => test:assertTrue(false, msg="Method 'depositMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        null => test:assertTrue(true, msg="Method 'depositMoney()' is not behaving as intended");
    }
}

// Unit test for testing depositMoney() function - failing scenario: due to invalid amount
@test:Config {
    dependsOn:["testCreateAccount"]
}
function testDepositMoneyFailCase1 () {
    // Create an account for username "Frank"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Frank");
    // Try to pass a negative amount to deposit
    match depositMoney(accountId, -100) {
        // An error is expected to be returned (not null) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless depositMoney function behaves erroneously
        null => test:assertTrue(false, msg="Method 'depositMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            string expectedErrMsg = "Error: Invalid amount";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'depositMoney()' is not behaving as intended");
        }
    }
}

// Unit test for testing depositMoney() function - failing scenario: due to invalid account
@test:Config
function testDepositMoneyFailCase2 () {
    // Provide a non existing account ID to method 'depositMoney()' and try to deposit $100
    match depositMoney(1234, 100) {
        // An error is expected to be returned (not null) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless depositMoney function behaves erroneously
        null => test:assertTrue(false, msg="Method 'depositMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            string expectedErrMsg = "Error: Account does not exist";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'depositMoney()' is not behaving as intended");
        }
    }
}

// Unit test for testing checkBalance() function - passing scenario
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testCheckBalancePass () {
    // Create an account for username "Grace"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Grace");
    // Deposit $500 to Grace's account
    _ = depositMoney(accountId, 500);
    // Check balance in Grace's account
    int balance =? checkBalance(accountId);
    // Grace should have $500 balance in account
    test:assertEquals(balance, 500, msg="Method 'checkBalance()' is not behaving as intended");
}

// Unit test for testing checkBalance() function - failing scenario: due to invalid account
@test:Config
function testCheckBalanceFail () {
    // Provide a non existing account ID to method 'checkBalance()'
    //// An error is expected in this case
    match checkBalance(1234) {
        // An error is expected to be returned (not int) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless checkBalance function behaves erroneously
        int balance => test:assertTrue(false, msg="Method 'checkBalance()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            // Expected error message
            string expectedErrMsg = "Error: Account does not exist";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'checkBalance()' is not behaving as intended");
        }
    }
}

// Unit test for testing withdrawMoney() function - passing scenario
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testWithdrawMoneyPass () {
    // Create an account for username "Heidi"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Heidi");
    // Deposit $500 to Heidi's account
    _ = depositMoney(accountId, 500);
    // Withdraw $300 from Heidi's account
    match withdrawMoney(accountId, 300) {
        // Expected return value is null (not any errors) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless withdrawMoney function behaves erroneously
        error err => test:assertTrue(false, msg="Method 'withdrawMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        null => test:assertTrue(true, msg="Method 'withdrawMoney()' is not behaving as intended");
    }
}

// Unit test for testing withdrawMoney() function - failing scenario: due to invalid amount
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testWithdrawMoneyFailCase1 () {
    // Create an account for username "Judy"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Judy");
    // Deposit $500 to Judy's account
    _ = depositMoney(accountId, 500);
    // Try to pass a negative amount to withdraw
    match withdrawMoney(accountId, -100) {
        // An error is expected to be returned (not null) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless withdrawMoney function behaves erroneously
        null => test:assertTrue(false, msg="Method 'withdrawMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            // Expected error message
            string expectedErrMsg = "Error: Invalid amount";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'withdrawMoney()' is not behaving as intended");
        }
    }
}

// Unit test for testing withdrawMoney() function - failing scenario: due to invalid account
@test:Config
function testWithdrawMoneyFailCase2 () {
    // Provide a non existing account ID to method 'withdrawMoney()'
    match withdrawMoney(1234, 200) {
        // An error is expected to be returned (not null) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless withdrawMoney function behaves erroneously
        null => test:assertTrue(false, msg="Method 'withdrawMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            // Expected error message
            string expectedErrMsg = "Error: Account does not exist";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'withdrawMoney()' is not behaving as intended");
        }
    }
}

// Unit test for testing withdrawMoney() function - failing scenario: due to not enough balance
// Unit test for testing withdrawMoney() function - failing scenario: due to invalid amount
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testWithdrawMoneyFailCase3 () {
    // Create an account for username "Merlin"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Merlin");
    // Deposit $500 to Merlin's account
    _ = depositMoney(accountId, 500);
    // Try to pass a big amount to withdraw, which is greater than the available balance
    match withdrawMoney(accountId, 1500) {
        // An error is expected to be returned (not null) - Therefore, the below should not be matched
        // Hence, the below assertion should not be executed unless withdrawMoney function behaves erroneously
        null => test:assertTrue(false, msg="Method 'withdrawMoney()' is not behaving as intended");
        // Below assertion is expected to be executed
        error err => {
            // Expected error message
            string expectedErrMsg = "Error: Not enough balance";
            // Test whether the error message is as expected
            test:assertEquals(err.message, expectedErrMsg, msg="Method 'withdrawMoney()' is not behaving as intended");
        }
    }
}

// Unit test for testing transferMoney() function - passing scenario
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testTransferMoneyPass () {
    // Create two new accounts for username "Walter" and "Wesley"
    int accountIdUser1 = createAccount("Walter");
    int accountIdUser2 = createAccount("Wesley");
    // Deposit $500 to Walter's account
    _ = depositMoney(accountIdUser1, 500);
    // Deposit $1000 to Wesley's account
    _ = depositMoney(accountIdUser2, 1000);
    // Transfer $700 from Wesley's account to Walter's account
    boolean isSuccessful = transferMoney(accountIdUser2, accountIdUser1, 700);
    // 'isSuccessful' should be true as transaction is expected to be successful
    test:assertTrue(isSuccessful, "Method 'transferMoney()' is not behaving as intended");
}

// Unit test for testing transferMoney() function - failing scenario: due to invalid amount
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testTransferMoneyFail1 () {
    // Create two new accounts for username "Victor" and "Vanna"
    int accountIdUser1 = createAccount("Victor");
    int accountIdUser2 = createAccount("Vanna");
    // Deposit $500 to Victor's account
    _ = depositMoney(accountIdUser1, 500);
    // Deposit $1000 to Vanna's account
    _ = depositMoney(accountIdUser2, 1000);
    // Try to pass a negative amount to transfer
    boolean isSuccessful = transferMoney(accountIdUser2, accountIdUser1, -200);
    // 'isSuccessful' should be false as transaction is expected to fail
    test:assertFalse(isSuccessful, "Method 'transferMoney()' is not behaving as intended");
}

// Unit test for testing transferMoney() function - failing scenario: due to not enough balance
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testTransferMoneyFail2 () {
    // Create two new accounts for username "Trent" and "Ted"
    int accountIdUser1 = createAccount("Trent");
    int accountIdUser2 = createAccount("Ted");
    // Deposit $500 to Trent's account
    _ = depositMoney(accountIdUser1, 500);
    // Deposit $1000 to Ted's account
    _ = depositMoney(accountIdUser2, 1000);
    // Try to pass a big amount to Transfer, which is greater than the available balance
    boolean isSuccessful = transferMoney(accountIdUser2, accountIdUser1, 1500);
    // 'isSuccessful' should be false as transaction is expected to fail
    test:assertFalse(isSuccessful, "Method 'transferMoney()' is not behaving as intended");
}

// Unit test for testing transferMoney() function - failing scenario: due to invalid transferor account ID
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testTransferMoneyFail3 () {
    // Create an account for username "Broad"
    int accountId = createAccount("Broad");
    // Deposit $500 to Broad's account
    _ = depositMoney(accountId, 500);
    // Provide a non existing account ID as transferor account ID to method 'transferMoney()'
    boolean isSuccessful = transferMoney(1234, accountId, 100);
    // 'isSuccessful' should be false as transaction is expected to fail
    test:assertFalse(isSuccessful, "Method 'transferMoney()' is not behaving as intended");
}

// Unit test for testing transferMoney() function - failing scenario: due to invalid transferee account ID
@test:Config {
    dependsOn:["testCreateAccount", "testDepositMoneyPass"]
}
function testTransferMoneyFail4 () {
    // Create an account for username "White"
    int accountId = createAccount("White");
    // Deposit $500 to White's account
    _ = depositMoney(accountId, 500);
    // Provide a non existing account ID as transferee to method 'transferMoney()'
    boolean isSuccessful = transferMoney(accountId, 1234, 100);
    // 'isSuccessful' should be false as transaction is expected to fail
    test:assertFalse(isSuccessful, "Method 'transferMoney()' is not behaving as intended");
}
