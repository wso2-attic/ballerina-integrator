# Database Transactions

A transaction is a small unit of a program that must maintain Atomicity, Consistency, Isolation, and Durability − 
commonly known as ACID properties − in order to ensure accuracy, completeness, and data integrity.

> In this guide, you will learn about managing database transactions using Ballerina. Please note that Ballerina
> transactions is an experimental feature. Please use `--experimental` flag when compiling Ballerina files which
> contain transaction related constructs.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you’ll build 
To understand how you can manage database transactions using Ballerina, let’s consider a real-world use case of a simple banking application.
This banking application allows users to,

- **Create accounts** : Create a new account by providing username
- **Verify accounts** : Verify the existence of an account by providing the account Id
- **Check balance**   : Check account balance
- **Deposit money**   : Deposit money into an account
- **Withdraw money**  : Withdraw money from an account
- **Transfer money**  : Transfer money from one account to another account

Transferring money from one account to another account involves both operations withdrawal from the transferor and deposit to the transferee. 

Let's assume the transaction fails during the deposit operation. Now the withdrawal operation carried out prior to 
deposit operation also needs to be rolled-back. Otherwise, we will end up in a state where transferor loses money. 
Therefore, to ensure the atomicity (all or nothing property), we need to perform the money transfer operation as a transaction. 

This example explains three different scenarios where one user tries to transfer money from his/her account to another user's account.
The first scenario shows a successful transaction whereas the other two fail due to different reasons.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [MySQL](https://dev.mysql.com/downloads/)
- [JDBC driver](https://dev.mysql.com/downloads/connector/j/)
    - Copy the downloaded JDBC driver jar file into the` <BALLERINA_HOME>/bre/lib` folder 

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping "Implementation" section.    

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
managing-database-transactions
 └── guide
      ├── ballerina.conf
      └── banking_application
           ├── account_manager.bal
           ├── application.bal
           └── tests
                └── account_manager_test.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `managing-database-transactions/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Implementation

Let's get started with the implementation of the `transferMoney` function of `account_manager`.
This function explains how we can use transactions in Ballerina. It comprises of two different operations, withdrawal
and deposit. To ensure that the transferring operation happens as a whole, it needs to reside in a database transaction block.
Transactions guarantee the 'ACID' properties. So if any of the withdrawal or deposit fails, the transaction will be aborted and all the operations carried out in the same transaction will be rolled back.
The transaction will be successful only when both, withdrawal from the transferor and deposit to the transferee are successful. 

The below code segment shows the implementation of function `transferMoney`. Inline comments added for better 
understanding. 

##### transferMoney function
```ballerina
// Function to transfer money from one account to another.
public function transferMoney(int fromAccId, int toAccId, int amount) returns boolean {
    boolean isSuccessful = false;
    log:printInfo("Initiating transaction");
    // Transaction block - Ensures the 'ACID' properties.
    // Withdraw and deposit should happen as a transaction when transferring money from one account to another.
    // Here, the reason for switching off the 'retries' option is, in failing scenarios almost all the time
    // transaction fails due to erroneous operations triggered by the users.
    transaction with retries = 0 {
        // Withdraw money from transferor's account.
        var withdrawRet = withdrawMoney(fromAccId, amount);
        if (withdrawRet is ()) {
            var depositRet = depositMoney(toAccId, amount);
            if (depositRet is ()) {
                isSuccessful = true;
            } else {
                log:printError("Error while depositing the money: " + depositRet.reason());
                // Abort transaction if deposit fails.
                log:printError("Failed to transfer money from account ID " + fromAccId + " to account ID " +
                    toAccId);
                abort;
            }
        } else {
            log:printError("Error while withdrawing the money: " + withdrawRet.reason());
            // Abort transaction if withdrawal fails.
            log:printError("Failed to transfer money from account ID " + fromAccId + " to account ID " + toAccId);
            abort;
        }
    } committed {
        log:printInfo("Transaction: " + transactions:getCurrentTransactionId() + " committed");
        // If transaction successful.
        log:printInfo("Successfully transferred $" + amount + " from account ID " + fromAccId + " to account ID " +
                toAccId);
    } aborted {
        log:printInfo("Transaction: " + transactions:getCurrentTransactionId() + " aborted");
    }
    return isSuccessful;
}
```

Let's now look at the implementation of the `account_manager`, which includes the account management related logic. 
It consists of functions to create an account, verify an account, check account balance, withdraw money from an account, deposit money to an account, and transfer money from one account to another. 
Skeleton of the `account_manager.bal` file attached below.

##### account_manager.bal
```ballerina
// Imports

// MySQL Client
mysql:Client bankDB = new({
        host: config:getAsString("DATABASE_HOST", defaultValue = "localhost"),
        port: config:getAsInt("DATABASE_PORT", defaultValue = 3306),
        name: config:getAsString("DATABASE_NAME", defaultValue = "bankDB"),
        username: config:getAsString("DATABASE_USERNAME", defaultValue = "root"),
        password: config:getAsString("DATABASE_PASSWORD", defaultValue = "root"),
        dbOptions: { useSSL: false }
    });

// Function to add users to 'ACCOUNT' table of 'bankDB' database
public function createAccount(string name) returns (int|error) {
    // Implemetation
    // Return the primary key, which will be the account number of the account
    // or an error in case of a failure
}

// Function to verify an account whether it exists or not
public function verifyAccount(int accId) returns (boolean|error) {
    // Implementation
    // Return a boolean, which is true if account exists; false otherwise
    // Or an error in case of a failure
}

// Function to check balance in an account
public function checkBalance(int accId) returns (int|error) {
    // Implementation
    // Return the balance or error
}

// Function to deposit money to an account
public function depositMoney(int accId, int amount) returns error|()  {
    // Implementation
    // Return error or ()
}

// Function to withdraw money from an account
public function withdrawMoney(int accId, int amount) returns (error|()) {
    // Implementation
    // Return error or ()
}

// Function to transfer money from one account to another
public function transferMoney(int fromAccId, int toAccId, int amount) returns boolean {
    // Implementation
    // Return a boolean, which is true if transaction is successful; false otherwise
}
```

To check the complete implementation of the above, refer to the [account_manager.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/guide/banking_application/account_manager.bal).

Let's next focus on the implementation of `application.bal` file, which includes the main function. It consists of three possible scenarios to check the transfer money operation of our banking application to explain the database transaction management using Ballerina.
Skeleton of `application.bal` file attached below.

##### application.bal

```ballerina
// Imports

public function main () {
    // Create two new accounts
    int accIdUser1 = createAccount("Alice");
    int accIdUser2 = createAccount("Bob");

    // Deposit money to both new accounts
    var depositRet1 = depositMoney(accIdUser1, 500);
    var depositRet2 = depositMoney(accIdUser2, 1000);

    // Scenario 1 - Transaction expected to be successful
    var transferRet1 = transferMoney(accIdUser1, accIdUser2, 300);

    // Scenario 2 - Transaction expected to fail due to insufficient ballance
    // 'accIdUser1' now only has a balance of 200
    var transferRet2 = transferMoney(accIdUser1, accIdUser2, 500);

    // Scenario 3 - Transaction expected to fail due to invalid recipient account ID
    // Account ID 1234 does not exist
    var transferRet3 = transferMoney(accIdUser2, 1234, 500);
    
    // Check the balance in Bob's account
    var checkBalanceRet = checkBalance(accIdUser2);
}
```

To check the complete implementation of the above, refer to the [application.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/guide/banking_application/application.bal). 

## Testing 

### Before you begin
- Run the SQL script `database_initializer.sql` provided in the resources folder, to initialize the database and to create the required table.
```bash
   $mysql -u username -p <database_initializer.sql 
``` 

NOTE : You can find the SQL script [here](./resources/database_initializer.sql).

- Add database configurations to the `ballerina.conf` file.
   - `ballerina.conf` file can be used to provide external configurations to the Ballerina programs. Since this guide needs MySQL database integration, a Ballerina configuration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
```
   DATABASE_HOST = "localhost"
   DATABASE_PORT = 3306
   DATABASE_NAME = "bankDB"
   DATABASE_USERNAME = "root"
   DATABASE_PASSWORD = "root"
```

- Navigate to `managing-database-transactions/guide` and execute the following command in a terminal to run this sample.

```bash
   $ ballerina run --experimental banking_application
```

### Response you'll get

We created two user accounts for users 'Alice' and 'Bob'. Then initially we deposited $500 to Alice's account and $1000 to Bob's account.
Later we had three different scenarios to check the money transfer operation, which includes a database transaction. 

Let's now look at some important log statements we will get as the response for these three scenarios.

- For the `scenario 1` where 'Alice' transfers $300 to Bob's account, the transaction is expected to be successful

```
------------------------------------ Scenario 1---------------------------------------- 
INFO  [banking_application] - Transfer $300 from Alice's account to Bob's account 
INFO  [banking_application] - Expected: Transaction to be successful 
INFO  [banking_application] - Initiating transaction 
INFO  [banking_application] - Verifying whether account ID 1 exists
INFO  [banking_application] - Available balance in account ID 1: 500
INFO  [banking_application] - Withdrawing money from account ID: 1 
INFO  [banking_application] - $300 has been withdrawn from account ID 1 
INFO  [banking_application] - Verifying whether account ID 2 exists
INFO  [banking_application] - Depositing money to account ID: 2 
INFO  [banking_application] - $300 has been deposited to account ID 2 
INFO  [banking_application] - Transaction committed 
INFO  [banking_application] - Successfully transferred $300 from account ID 1 to account ID
```

- For the `scenario 2` where 'Alice' tries to transfer $500 to Bob's account, the transaction is expected to fail as 'Alice' has an insufficient balance

```
------------------------------------ Scenario 2---------------------------------------- 
INFO  [banking_application] - Again try to transfer $500 from Alice's account to Bob's account
INFO  [banking_application] - Expected: Transaction to fail as Alice now only has a balance of $200 in account
INFO  [banking_application] - Initiating transaction 
INFO  [banking_application] - Verifying whether account ID 1 exists
INFO  [banking_application] - Available balance in account ID 1: 200
ERROR [banking_application] - Error while withdrawing the money: Error: Not enough balance
ERROR [banking_application] - Failed to transfer money from account ID 1 to account ID 2
INFO  [banking_application] - Transaction aborted
```

- For the `scenario 3` where 'Bob' tries to transfer $500 to account ID 1234, the transaction is expected to fail as account ID 1234 does not exist

```
------------------------------------ Scenario 3---------------------------------------- 
INFO  [banking_application] - Try to transfer $500 from Bob's account to a non existing account ID
INFO  [banking_application] - Expected: Transaction to fail as account ID of recipient is invalid
INFO  [banking_application] - Initiating transaction 
INFO  [banking_application] - Verifying whether account ID 2 exists
INFO  [banking_application] - Available balance in account ID 2: 1300
INFO  [banking_application] - Withdrawing money from account ID: 2 
INFO  [banking_application] - $500 has been withdrawn from account ID 2 
INFO  [banking_application] - Verifying whether account ID 1234 exists 
ERROR [banking_application] - Error while depositing the money: Error: Account does not exist
ERROR [banking_application] - Failed to transfer money from account ID 2 to account ID 1234
INFO  [banking_application] - Check balance for Bob's account
INFO  [banking_application] - Verifying whether account ID 2 exists
INFO  [banking_application] - Available balance in account ID 2: 1300
INFO  [banking_application] - You should see $1300 balance in Bob's account (NOT $800)
INFO  [banking_application] - Explanation: 
When trying to transfer $500 from Bob's account to account ID 1234, initially $500
was withdrawn from Bob's account. But then the deposit operation failed due to an invalid
recipient account ID; Hence, the transaction failed and withdraw operation rollbacked as 
it is in same transaction
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testCreateAccount() {
```
  
This guide contains unit tests for each method available in the `account_manager`.

To run the unit tests, navigate to `managing-database-transactions/guide` and run the following command. 
```bash
   $ ballerina test --experimental
```
Please note that `--config` option is required if it is needed to read configurations from a ballerina configuration file

To check the implementation of the test file, refer to the [account_manager_test.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/guide/banking_application/tests/account_manager_test.bal).
