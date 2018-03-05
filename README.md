# Managing Database Transactions
In this guide, you will learn about managing database transactions using Ballerina.

## <a name="what-you-build"></a> What you’ll build 
To understanding how you can manage database transactions using Ballerina, let’s consider a real-world use case of a simple banking application. In this example, you will build a simple banking application, which will allow users to,

- **Create accounts** : Create a new account by providing username
- **Verify accounts** : Verify the existence of an account by providing the account Id
- **Check balance** : Check account balance
- **Deposit money** : Deposit money into an account
- **Withdraw money** : Withdraw money from an account
- **Transfer money** : Transfer money from one account to another account


Transferring money from one account to another account involves both operations withdrawal from the transferor and deposit to the transferee. Hence transferring operation required to be done using a transaction block. A transaction ensures the 'ACID' properties, which database transactions intended to guarantee validity even in the event of errors, power failures, etc.

When transferring money assume the transaction fails during the deposit operation. Now the withdrawal operation carried out prior to deposit operation also needs to be rolled back. Otherwise, we will end up in a state where transferor loses money. Therefore, to ensure the atomicity (all or nothing property), we need to perform the money transfer operation as a transaction. 

This example explains three different scenarios where one user tries to transfer money from his/her account to another user's account. The first scenario shows a successful transaction whereas the other two fail due to different reasons. You can observe how Ballerina transactions ensure the 'ACID' properties through this example.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/)
  * Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder 
- A Text Editor or an IDE 

Optional requirements
- Ballerina IDE plugins (IntelliJ IDEA, VSCode, Atom)

## <a name="develop-app"></a> Developing the application
### <a name="before-begin"></a> Before you begin
##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
managing-database-transactions
├── ballerina.conf
├── BankingApplication
│   ├── account_manager.bal
│   ├── account_manager_test.bal
│   ├── application.bal
│   └── dbUtil
│       ├── database_utilities.bal
│       └── database_utilities_test.bal
└── README.md

```
##### Add database configurations to the `ballerina.conf` file
The purpose of  `ballerina.conf` file is to provide any external configurations that are required by ballerina programs. Since we need to interact with MySQL database, we can provide the database connection properties to the ballerina program via `ballerina.conf` file.
This configuration file will have the following fields,

```
DATABASE_HOST = localhost
DATABASE_PORT = 3306
DATABASE_USERNAME = username
DATABASE_PASSWORD = password
DATABASE_MAX_POOL_SIZE = 5
DATABASE_NAME = bankDB
```
Make sure to edit these configurations with your MySQL database connection properties. You can keep the DATABASE_NAME as it is if you don't want to change the name explicitly.

### <a name="Implementation"></a> Implementation

Let's get started with the implementation of the function `transferMoney` in `account_manager.bal` file. This function explains how we can use transactions in Ballerina. It comprises of two different operations, withdrawal and deposit. To ensure that the transferring operation happens as a whole, it needs to reside in a database transaction block. Transactions guarantee the 'ACID' properties. So if any of the withdrawal or deposit fails, the transaction will be aborted and all the operations carried out in the same transaction will be rolled back. The transaction will be successful only when both, withdrawal from the transferor and deposit to the transferee are successful. 

The below code segment shows the implementation of function `transferMoney`. Inline comments used for better understandings. 

##### transferMoney function
```ballerina
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
            log:printError("Error while withdrawing the money: " + withdrawError.msg);
            // Abort transaction if withdrawal fails
            abort;
        }
        // Deposit money to transferee's account
        error depositError = depositMoney(toAccId, amount);
        if (depositError != null) {
            log:printError("Error while depositing the money: " + depositError.msg);
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
```

Let's now look at the implementation of the `account_manager.bal`, which includes the account management related logic. It consists of a private method to initialize the database and public functions to create an account, verify an account, check account balance, withdraw money from an account, deposit money to an account, and transfer money from one account to another. 
Skeleton of the `account_manager.bal` is given below.

##### account_manager.bal
```ballerina
package BankingApplication;

// Imports

// Get the SQL client connector
sql:ClientConnector sqlConnector = dbUtil:getDatabaseClientConnector();

// Execute the database initialization function
boolean init = initializeDB();

// Function to add users to 'ACCOUNT' table of 'bankDB' database
public function createAccount (string name) (int accId) {
    // Implemetation
    
    // Return the primary key, which will be the account number of the account
    return;
}

// Function to verify an account whether it exists or not
public function verifyAccount (int accId) (boolean accExists) {
    // Implementation
    
    // Return a boolean, which will be true if account exists; false otherwise
    return;
}

// Function to check balance in an account
public function checkBalance (int accId) (int balance, error err) {
    // Implementation

    // Return the balance
    return;
}

// Function to deposit money to an account
public function depositMoney (int accId, int amount) (error err) {
    // Implementation

    // Return error if amount is invalid or account does not exist
    return;
}

// Function to withdraw money from an account
public function withdrawMoney (int accId, int amount) (error err) {
    // Implementation
    
    // Return error if amount is invalid or account does not exist or if balance is not enough
    return;
}

// Function to transfer money from one account to another
public function transferMoney (int fromAccId, int toAccId, int amount) (boolean isSuccessful) {
    // Implementation 
   
    // Return a boolean, which will be true if transaction is successful; false otherwise
    return;
}

// Private function to initialize the database
function initializeDB () (boolean isInitialized) {
    // Implementation 
    
    // Return a boolean, which will be true if the initialization is successful; false otherwise
    return;
}

```

To see the complete implementation of `account_manager.bal` file, refer https://github.com/ballerina-guides/managing-database-transactions/blob/master/BankingApplication/account_manager.bal.

Let's next focus on the implementation of `application.bal` file, which includes the main function. It consists of three possible scenarios to check the transfer money operation of our banking application to explain the database transaction management using Ballerina. Skeleton of `application.bal` is attached below.


##### application.bal

```ballerina
package BankingApplication;

// Imports

function main (string[] args) {
    // Create two new accounts
    int accIdUser1 = createAccount("Alice");
    int accIdUser2 = createAccount("Bob");

    // Deposit money to both new accounts
    _ = depositMoney(accIdUser1, 500);
    _ = depositMoney(accIdUser2, 1000);

    // Scenario 1 - Transaction expected to be successful
    _ = transferMoney(accIdUser1, accIdUser2, 300);

    // Scenario 2 - Transaction expected to fail due to insufficient ballance
    // 'accIdUser1' now only has a balance of 200
    _ = transferMoney(accIdUser1, accIdUser2, 500);

    // Scenario 3 - Transaction expected to fail due to invalid recipient account ID
    // Account ID 1234 does not exist
    _ = transferMoney(accIdUser2, 1234, 500);
}

```

To see the complete implementation of `application.bal` file, refer https://github.com/ballerina-guides/managing-database-transactions/blob/master/BankingApplication/application.bal. 


Finally, let's focus on the implementation of `database_utilities.bal`, which consists database utility functions. Before accessing the database from ballerina, we need to have the SQL client connector. We also need a function to create databases if we decide to do it from the code itself. 
File `database_utilities.bal` in the dbUtil package includes the implementations for the above-mentioned functions. Skeleton of this file is attached below. Inline comments are used to explain the important code segments.

##### database_utilities.bal
```ballerina
package BankingApplication.dbUtil;

// Imports

// Function to get SQL database client connector
public function getDatabaseClientConnector () (sql:ClientConnector sqlConnector) {
    // Get database configuration details from the ballerina.config file
    // Implementation
    
    // Return the SQL client connector
    return;
}

// Function to create a database
public function createDatabase (sql:ClientConnector sqlConnector, string dbName) (int updateStatus) {
    // Implementation
    
    // Return the update status
    return;
}

```

To see the complete implementation of `database_utilities.bal` file, refer https://github.com/ballerina-guides/managing-database-transactions/blob/master/BankingApplication/dbUtil/database_utilities.bal.


## <a name="testing"></a> Testing 

### <a name="try-out"></a> Try it out

Run this sample by entering the following command in a terminal,

```bash
<SAMPLE_ROOT_DIRECTORY>$ ballerina run BankingApplication/
```

#### <a name="response"></a> Response you'll get

```
2018-02-16 07:16:33,259 INFO  [BankingApplication] - ------------------------------- DB Initialization ------------------------------- 
2018-02-16 07:16:33,264 INFO  [BankingApplication] - Creating database 'bankDB' if not exists; Status: 1 
2018-02-16 07:16:33,265 INFO  [BankingApplication] - Selecting database: 'bankDB'; Status: 0 
2018-02-16 07:16:33,289 INFO  [BankingApplication] - Dropping table 'ACCOUNT' if exists; Status: 0 
2018-02-16 07:16:33,323 INFO  [BankingApplication] - Creating table 'ACCOUNT'; Status: 0
 
2018-02-16 07:16:33,330 INFO  [BankingApplication] - ---------------------------------------------------------------------------------- 
2018-02-16 07:16:33,330 INFO  [BankingApplication] - Creating two new accounts for users 'Alice' and 'Bob' 
2018-02-16 07:16:33,341 INFO  [BankingApplication] - Creating account for user: 'Alice'; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,514 INFO  [BankingApplication] - Account ID for user: 'Alice': 1 
2018-02-16 07:16:33,519 INFO  [BankingApplication] - Creating account for user: 'Bob'; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,521 INFO  [BankingApplication] - Account ID for user: 'Bob': 2 
2018-02-16 07:16:33,522 INFO  [BankingApplication] - Deposit $500 to Alice's account initially 
2018-02-16 07:16:33,522 INFO  [BankingApplication] - Depositing money to account ID: 1 
2018-02-16 07:16:33,522 INFO  [BankingApplication] - Verifying whether account ID 1 exists 
2018-02-16 07:16:33,530 INFO  [BankingApplication] - Updating balance for account ID: 1; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,531 INFO  [BankingApplication] - $500 has been deposited to account ID 1 
2018-02-16 07:16:33,531 INFO  [BankingApplication] - Deposit $1000 to Bob's account initially 
2018-02-16 07:16:33,531 INFO  [BankingApplication] - Depositing money to account ID: 2 
2018-02-16 07:16:33,532 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,537 INFO  [BankingApplication] - Updating balance for account ID: 2; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,537 INFO  [BankingApplication] - $1000 has been deposited to account ID 2 
2018-02-16 07:16:33,537 INFO  [BankingApplication] - 

--------------------------------------------------------------- Scenario 1-------------------------------------------------------------- 
2018-02-16 07:16:33,538 INFO  [BankingApplication] - Transfer $300 from Alice's account to Bob's account 
2018-02-16 07:16:33,538 INFO  [BankingApplication] - Expected: Transaction to be successful 
2018-02-16 07:16:33,539 INFO  [BankingApplication] - Initiating transaction 
2018-02-16 07:16:33,540 INFO  [BankingApplication] - Transfering money from account ID 1 to account ID 2 
2018-02-16 07:16:33,541 INFO  [BankingApplication] - Withdrawing money from account ID: 1 
2018-02-16 07:16:33,541 INFO  [BankingApplication] - Checking balance for account ID: 1 
2018-02-16 07:16:33,541 INFO  [BankingApplication] - Verifying whether account ID 1 exists 
2018-02-16 07:16:33,544 INFO  [BankingApplication] - Available balance in account ID 1: 500 
2018-02-16 07:16:33,545 INFO  [BankingApplication] - Updating balance for account ID: 1; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,545 INFO  [BankingApplication] - $300 has been withdrawn from account ID 1 
2018-02-16 07:16:33,545 INFO  [BankingApplication] - Depositing money to account ID: 2 
2018-02-16 07:16:33,546 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,549 INFO  [BankingApplication] - Updating balance for account ID: 2; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,549 INFO  [BankingApplication] - $300 has been deposited to account ID 2 
2018-02-16 07:16:33,550 INFO  [BankingApplication] - Transaction committed 
2018-02-16 07:16:33,550 INFO  [BankingApplication] - Successfully transferred $300 from account ID 1 to account ID 2 
2018-02-16 07:16:33,555 INFO  [BankingApplication] - Check balance for Alice's account 
2018-02-16 07:16:33,556 INFO  [BankingApplication] - Checking balance for account ID: 1 
2018-02-16 07:16:33,556 INFO  [BankingApplication] - Verifying whether account ID 1 exists 
2018-02-16 07:16:33,559 INFO  [BankingApplication] - Available balance in account ID 1: 200 
2018-02-16 07:16:33,559 INFO  [BankingApplication] - You should see $200 balance in Alice's account 
2018-02-16 07:16:33,560 INFO  [BankingApplication] - Check balance for Bob's account 
2018-02-16 07:16:33,560 INFO  [BankingApplication] - Checking balance for account ID: 2 
2018-02-16 07:16:33,561 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,563 INFO  [BankingApplication] - Available balance in account ID 2: 1300 
2018-02-16 07:16:33,564 INFO  [BankingApplication] - You should see $1300 balance in Bob's account 
2018-02-16 07:16:33,564 INFO  [BankingApplication] - 

--------------------------------------------------------------- Scenario 2-------------------------------------------------------------- 
2018-02-16 07:16:33,564 INFO  [BankingApplication] - Again try to transfer $500 from Alice's account to Bob's account 
2018-02-16 07:16:33,565 INFO  [BankingApplication] - Expected: Transaction to fail as Alice now only has a balance of $200 in account 
2018-02-16 07:16:33,565 INFO  [BankingApplication] - Initiating transaction 
2018-02-16 07:16:33,565 INFO  [BankingApplication] - Transfering money from account ID 1 to account ID 2 
2018-02-16 07:16:33,566 INFO  [BankingApplication] - Withdrawing money from account ID: 1 
2018-02-16 07:16:33,566 INFO  [BankingApplication] - Checking balance for account ID: 1 
2018-02-16 07:16:33,566 INFO  [BankingApplication] - Verifying whether account ID 1 exists 
2018-02-16 07:16:33,569 INFO  [BankingApplication] - Available balance in account ID 1: 200 
2018-02-16 07:16:33,570 ERROR [BankingApplication] - Error while withdrawing the money: Error: Not enough balance 
2018-02-16 07:16:33,570 INFO  [BankingApplication] - Check balance for Alice's account 
2018-02-16 07:16:33,571 INFO  [BankingApplication] - Checking balance for account ID: 1 
2018-02-16 07:16:33,571 INFO  [BankingApplication] - Verifying whether account ID 1 exists 
2018-02-16 07:16:33,574 INFO  [BankingApplication] - Available balance in account ID 1: 200 
2018-02-16 07:16:33,574 INFO  [BankingApplication] - You should see $200 balance in Alice's account 
2018-02-16 07:16:33,574 INFO  [BankingApplication] - Check balance for Bob's account 
2018-02-16 07:16:33,575 INFO  [BankingApplication] - Checking balance for account ID: 2 
2018-02-16 07:16:33,575 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,577 INFO  [BankingApplication] - Available balance in account ID 2: 1300 
2018-02-16 07:16:33,578 INFO  [BankingApplication] - You should see $1300 balance in Bob's account 
2018-02-16 07:16:33,578 INFO  [BankingApplication] - 

--------------------------------------------------------------- Scenario 3-------------------------------------------------------------- 
2018-02-16 07:16:33,578 INFO  [BankingApplication] - Try to transfer $500 from Bob's account to a non existing account ID 
2018-02-16 07:16:33,579 INFO  [BankingApplication] - Expected: Transaction to fail as account ID of recipient is invalid 
2018-02-16 07:16:33,579 INFO  [BankingApplication] - Initiating transaction 
2018-02-16 07:16:33,579 INFO  [BankingApplication] - Transfering money from account ID 2 to account ID 123 
2018-02-16 07:16:33,580 INFO  [BankingApplication] - Withdrawing money from account ID: 2 
2018-02-16 07:16:33,580 INFO  [BankingApplication] - Checking balance for account ID: 2 
2018-02-16 07:16:33,580 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,583 INFO  [BankingApplication] - Available balance in account ID 2: 1300 
2018-02-16 07:16:33,584 INFO  [BankingApplication] - Updating balance for account ID: 2; Rows affected in ACCOUNT table: 1 
2018-02-16 07:16:33,584 INFO  [BankingApplication] - $500 has been withdrawn from account ID 2 
2018-02-16 07:16:33,585 INFO  [BankingApplication] - Depositing money to account ID: 123 
2018-02-16 07:16:33,585 INFO  [BankingApplication] - Verifying whether account ID 123 exists 
2018-02-16 07:16:33,589 ERROR [BankingApplication] - Error while depositing the money: Error: Account does not exist 
2018-02-16 07:16:33,598 INFO  [BankingApplication] - Check balance for Bob's account 
2018-02-16 07:16:33,598 INFO  [BankingApplication] - Checking balance for account ID: 2 
2018-02-16 07:16:33,598 INFO  [BankingApplication] - Verifying whether account ID 2 exists 
2018-02-16 07:16:33,601 INFO  [BankingApplication] - Available balance in account ID 2: 1300 
2018-02-16 07:16:33,601 INFO  [BankingApplication] - You should see $1300 balance in Bob's account (NOT $800) 
2018-02-16 07:16:33,601 INFO  [BankingApplication] - Explanation: When trying to transfer $500 from Bob's account to account ID 123, 
initially $500 withdrawed from Bob's account. But then the deposit operation failed due to an invalid recipient account ID; Hence 
the TX failed and the withdraw operation rollbacked, which is in the same TX

```

### <a name="unit-testing"></a> Writing unit tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g.: testCreateAccount()

This guide contains unit test cases for each method implemented in `database_utilities.bal` and `account_manager.bal` files.
Test files are in the same packages in which the above files are located.

To run the unit tests, go to the sample root directory and run the following command,

```bash
$ ballerina test BankingApplication/
```

To check the implementations of these test files, please go to https://github.com/ballerina-guides/managing-database-transactions/blob/master/BankingApplication/ and refer the respective folders of `database_utilities.bal` and `account_manager.bal` files.
