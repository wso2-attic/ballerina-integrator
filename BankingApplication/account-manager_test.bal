package BankingApplication;

import ballerina.test;

// Unit test for testing initializeDB() function
function testInitializeDB () {
    boolean isInitialized = initializeDB();
    // Initialization expected to be successful
    // Expected boolean value for variable 'isInitialized' is true
    test:assertTrue(isInitialized, "Failed to initialize the database properly");
}

// Unit test for testing createAccount() function
function testCreateAccount () {
    string name = "Carol";
    // Create account for username "Carol"
    int accountId = createAccount(name);
    // 'AUTO_INCREMENT' starts from 1 and default value for int is 0 in Ballerina
    // Therefore, if account creation is successful then variable 'AccountId' should be greater than zero
    test:assertTrue(accountId > 0, "Failed to create account for user: " + name);
}

// Unit test for testing verifyAccount() function - passing scenario
function testVerifyAccountPass () {
    // Create an account for username "Dave"
    int accountId = createAccount("Dave");
    // Provide an existing account ID to method 'verifyAccount()' - Account ID corresponding to username "Dave"
    boolean accountExists = verifyAccount(accountId);
    // Expected boolean value for variable 'accountExists' is true
    test:assertTrue(accountExists, "Method 'verifyAccount()' is not behaving as intended");
}

// Unit test for testing verifyAccount() function - failing scenario: due to invalid account
function testVerifyAccountFail () {
    // Provide a non existing account ID to method 'verifyAccount()'
    boolean accountExists = verifyAccount(1234);
    // Expected boolean value for variable 'accountExists' is false
    test:assertFalse(accountExists, "Method 'verifyAccount()' is not behaving as intended");
}

// Unit test for testing depositMoney() function - passing scenario
function testDepositMoneyPass () {
    // Create an account for username "Elite"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Elite");
    // Deposit $500 to Elite's account
    error err = depositMoney(accountId, 500);
    // Error is expected to be null in this case
    test:assertTrue(err == null, "Method 'depositMoney()' is not behaving as intended");
}

// Unit test for testing depositMoney() function - failing scenario: due to invalid amount
function testDepositMoneyFailCase1 () {
    // Create an account for username "Frank"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Frank");
    // Try to pass a negative amount to deposit
    error err = depositMoney(accountId, -100);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'depositMoney()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Invalid amount";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'depositMoney()' is not behaving as intended");
}

// Unit test for testing depositMoney() function - failing scenario: due to invalid account
function testDepositMoneyFailCase2 () {
    // Provide a non existing account ID to method 'depositMoney()' and try to deposit $100
    error err = depositMoney(1234, 100);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'depositMoney()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Account does not exist";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'depositMoney()' is not behaving as intended");
}

// Unit test for testing checkBalance() function - passing scenario
function testCheckBalancePass () {
    // Create an account for username "Grace"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Grace");
    // Deposit $500 to Grace's account
    _ = depositMoney(accountId, 500);
    // Check balance in Grace's account
    var balance, err = checkBalance(accountId);
    // Error is expected to be null in this case
    test:assertTrue(err == null, "Method 'checkBalance()' is not behaving as intended");
    // Grace should have $500 balance in account
    test:assertIntEquals(balance, 500, "Method 'checkBalance()' is not behaving as intended");
}

// Unit test for testing checkBalance() function - failing scenario: due to invalid account
function testCheckBalanceFail () {
    // Provide a non existing account ID to method 'checkBalance()'
    var balance, err = checkBalance(1234);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'checkBalance()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Account does not exist";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'checkBalance()' is not behaving as intended");
    // 'balance' should be zero (default value)
    test:assertIntEquals(balance, 0, "Method 'checkBalance()' is not behaving as intended");
}

// Unit test for testing withdrawMoney() function - passing scenario
function testWithdrawMoneyPass () {
    // Create an account for username "Heidi"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Heidi");
    // Deposit $500 to Heidi's account
    _ = depositMoney(accountId, 500);
    // Withdraw $300 from Heidi's account
    error err = withdrawMoney(accountId, 300);
    // Error is expected to be null in this case
    test:assertTrue(err == null, "Method 'withdrawMoney()' is not behaving as intended");
}

// Unit test for testing withdrawMoney() function - failing scenario: due to invalid amount
function testWithdrawMoneyFailCase1 () {
    // Create an account for username "Judy"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Judy");
    // Deposit $500 to Judy's account
    _ = depositMoney(accountId, 500);
    // Try to pass a negative amount to withdraw
    error err = withdrawMoney(accountId, -100);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'withdrawMoney()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Invalid amount";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'withdrawMoney()' is not behaving as intended");
}

// Unit test for testing withdrawMoney() function - failing scenario: due to invalid account
function testWithdrawMoneyFailCase2 () {
    // Provide a non existing account ID to method 'withdrawMoney()'
    error err = withdrawMoney(1234, 200);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'withdrawMoney()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Account does not exist";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'withdrawMoney()' is not behaving as intended");
}

// Unit test for testing withdrawMoney() function - failing scenario: due to not enough balance
function testWithdrawMoneyFailCase3 () {
    // Create an account for username "Merlin"
    // This will create a new account with initial balance zero
    int accountId = createAccount("Merlin");
    // Deposit $500 to Merlin's account
    _ = depositMoney(accountId, 500);
    // Try to pass a big amount to withdraw, which is greater than the available balance
    error err = withdrawMoney(accountId, 1500);
    // An error is expected in this case
    test:assertFalse(err == null, "Method 'withdrawMoney()' is not behaving as intended");
    // Expected error message
    string expectedErrMsg = "Error: Not enough balance";
    // Test whether the error message is as expected
    test:assertStringEquals(err.msg, expectedErrMsg, "Method 'withdrawMoney()' is not behaving as intended");
}

// Unit test for testing transferMoney() function - passing scenario
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
