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

import ballerina/log;

public function main () {
    log:printInfo("----------------------------------------------------------------------------------");
    // Create two new accounts
    log:printInfo("Create two new accounts for users 'Alice' and 'Bob'");
    var createAccRet = createAccounts();
    int accIdUser1;
    int accIdUser2;
    if (createAccRet is (int, int)) {
        (accIdUser1, accIdUser2) = createAccRet;

        // Deposit money to both new accounts
        log:printInfo("Deposit $500 to Alice's account initially");
        var depositRet1 = depositMoney(accIdUser1, 500);
        if (depositRet1 is error) {
            log:printError("Error occurred while depositing", err = depositRet1);
        }
        log:printInfo("Deposit $1000 to Bob's account initially");
        var depositRet2 = depositMoney(accIdUser2, 1000);
        if (depositRet2 is error) {
            log:printError("Error occurred while depositing", err = depositRet1);
        }

        // Scenario 1 - Transaction expected to be successful
        log:printInfo("\n\n--------------------------------------------------------------- Scenario 1"
                + "--------------------------------------------------------------");
        log:printInfo("Transfer $300 from Alice's account to Bob's account");
        log:printInfo("Expected: Transaction to be successful");
        _ = transferMoney(accIdUser1, accIdUser2, 300);

        // Scenario 2 - Transaction expected to fail
        log:printInfo("\n\n--------------------------------------------------------------- Scenario 2"
                + "--------------------------------------------------------------");
        log:printInfo("Again try to transfer $500 from Alice's account to Bob's account");
        log:printInfo("Expected: Transaction to fail as Alice now only has a balance of $200 in account");
        _ = transferMoney(accIdUser1, accIdUser2, 500);

        // Scenario 3 - Transaction expected to fail
        log:printInfo("\n\n--------------------------------------------------------------- Scenario 3"
                + "--------------------------------------------------------------");
        log:printInfo("Try to transfer $500 from Bob's account to a non existing account ID");
        log:printInfo("Expected: Transaction to fail as account ID of recipient is invalid");
        _ = transferMoney(accIdUser2, 1234, 500);

        log:printInfo("Check balance for Bob's account");
        var checkBalanceRet = checkBalance(accIdUser2);
        if (checkBalanceRet is error) {
            log:printError("Error occurred while checking balance", err = checkBalanceRet);
        }
        log:printInfo("You should see $1300 balance in Bob's account (NOT $800)");
        log:printInfo(
                "Explanation: When trying to transfer $500 from Bob's account to account ID 1234, \ninitially $500 " +
                "withdrew from Bob's account. But then the deposit operation failed due to an invalid recipient " +
                "account ID; Hence, \nthe TX failed and the withdraw operation rollbacked as it is in the same TX " +
                "\n");
    } else {
        log:printError("Account creation failed", err = createAccRet);
    }
}

function createAccounts() returns (int, int)|error {
    var createAccRet1 = createAccount("Alice");
    (int,int)|error retVal;
    if (createAccRet1 is int) {
        var createAccRet2 = createAccount("Bob");
        if (createAccRet2 is int) {
           return (createAccRet1, createAccRet2) ;
        } else {
            error err = error("Account creation failed");
            return err;
        }
    } else {
        error err = error("Account creation failed");
        return err;
    }
}
