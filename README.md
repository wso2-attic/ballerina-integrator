# Transactions

In this guide, you will learn about managing database transactions using Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-application)
- [Testing](#testing)

## What you’ll build 
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

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/)
  * Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder 
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))


## Developing the application

### Before you begin

#### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
managing-database-transactions
  ├── resources
  │   └── DatabaseInitializer.sql
  └── src
      └── BankingApplication
          ├── account_manager.bal
          ├── application.bal
          └── test
              └── account_manager_test.bal              
```

#### Change the database configurations in the `account_manager.bal` file
As we need to interact with MySQL database, we should provide the database connection properties when defining the `sql:Client` endpoint. This is defined in the `account_manager.bal` file. 
The required configurations are,

```
host:<HOST>,
port:<PORT>,
name:<DATABASE_NAME>,
username:<USERNAME>,
password:<PASSWORD>,
options:{maximumPoolSize:<MAXIMUM_POOL_SIZE>}
```
Make sure to edit these configurations with your MySQL database connection properties. You can keep the <DATABASE_NAME> as available now if you don't want to change the name explicitly.

##### Run the `DatabaseInitializer.sql` script 
You have to run the mysql database script `DatabaseInitializer.sql` provided inside the resource folder to initialize the database with required table details.

### Implementation

Let's get started with the implementation of the function `transferMoney` in `account_manager.bal` file. This function explains how we can use transactions in Ballerina. It comprises of two different operations, withdrawal and deposit. To ensure that the transferring operation happens as a whole, it needs to reside in a database transaction block. Transactions guarantee the 'ACID' properties. So if any of the withdrawal or deposit fails, the transaction will be aborted and all the operations carried out in the same transaction will be rolled back. The transaction will be successful only when both, withdrawal from the transferor and deposit to the transferee are successful. 

The below code segment shows the implementation of function `transferMoney`. Inline comments used for better understandings. 

##### transferMoney function
```ballerina
// Function to transfer money from one account to another
public function transferMoney(int fromAccId, int toAccId, int amount) returns (boolean) {
    boolean isSuccessful;
    // Transaction block - Ensures the 'ACID' properties
    // Withdraw and deposit should happen as a transaction when transfering money from
    // one account to another
    transaction with retries = 0 {
        log:printInfo("Initiating transaction");
        // Withdraw money from transferor's account
        match withdrawMoney(fromAccId, amount) {
            error withdrawError => {
                log:printError("Error while withdrawing the money: " +
                    withdrawError.message);
                // Abort transaction if withdrawal fails
                log:printInfo("Transaction aborted");
                log:printError("Failed to transfer money from account ID " + fromAccId +
                    " to account ID " + toAccId);
                abort;
            }
            null => {
                match depositMoney(toAccId, amount) {
                    error depositError => {
                        log:printError("Error while depositing the money: " +
                            depositError.message);
                        // Abort transaction if deposit fails
                        log:printInfo("Transaction aborted");
                        log:printError("Failed to transfer money from account ID " +
                            fromAccId + " to account ID " + toAccId);
                        abort;
                    }
                    null => isSuccessful = true;
                }
            }
        }
        // If transaction successful
        log:printInfo("Transaction committed");
        log:printInfo("Successfully transferred $" + amount + " from account ID " +
            fromAccId + " to account ID " + toAccId);
    }
    return isSuccessful;
}
```

Let's now look at the implementation of the `account_manager.bal`, which includes the account management related logic. It consists of a private method to initialize the database and public functions to create an account, verify an account, check account balance, withdraw money from an account, deposit money to an account, and transfer money from one account to another. 
Skeleton of the `account_manager.bal` is given below.

##### account_manager.bal
```ballerina
package BankingApplication;

// Imports

endpoint sql:Client bankDB {
    database:sql:DB.MYSQL,
    host:"localhost",
    port:3306,
    name:"bankDB",
    username:<USERNAME>,
    password:<PASSWORD>,
    options:{maximumPoolSize:5}
};

// Function to add users to 'ACCOUNT' table of 'bankDB' database
public function createAccount(string name) returns (int) {
    // Implemetation
    // Return the primary key, which will be the account number of the account
}

// Function to verify an account whether it exists or not
public function verifyAccount(int accId) returns (boolean) {
    // Implementation
    // Return a boolean, which will be true if account exists; false otherwise
}

// Function to check balance in an account
public function checkBalance(int accId) returns (int|error) {
    // Implementation
    // Return the balance or error
}

// Function to deposit money to an account
public function depositMoney(int accId, int amount) returns (error|null) {
    // Implementation
    // Return error or null
}

// Function to withdraw money from an account
public function withdrawMoney(int accId, int amount) returns (error|null) {
    // Implementation
    // Return error or null
}

// Function to transfer money from one account to another
public function transferMoney(int fromAccId, int toAccId, int amount) returns (boolean) {
    // Implementation
    // Return a boolean, which will be true if transaction is successful; false otherwise
}
```

To see the complete implementation of the above, refer [account_manager.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/src/BankingApplication/account_manager.bal).

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

To see the complete implementation of the above, refer [application.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/src/BankingApplication/application.bal). 

## Testing 

### Try it out

Run this sample by entering the following command in a terminal,

```
<SAMPLE_ROOT_DIRECTORY>/src$ ballerina run BankingApplication/
```

#### Response you'll get

We created two user accounts for users 'Alice' and 'Bob'. Then initially we deposited $500 to Alice's account and $1000 to Bob's account. Later we had three different scenarios to check the money transfer operation, which is carried out as a database transaction. 

Let's now look at some important log statements we will get as the response for these three scenarios.

- For the `scenario 1` where 'Alice' transfers $300 to Bob's account, the transaction is expected to be successful

```
----------------------------------------- Scenario 1--------------------------------------------- 
INFO  [BankingApplication] - Transfer $300 from Alice's account to Bob's account 
INFO  [BankingApplication] - Expected: Transaction to be successful 
INFO  [BankingApplication] - Initiating transaction 
INFO  [BankingApplication] - Transfering money from account ID 1 to account ID 2 
INFO  [BankingApplication] - Withdrawing money from account ID: 1 
INFO  [BankingApplication] - $300 has been withdrawn from account ID 1 
INFO  [BankingApplication] - Depositing money to account ID: 2 
INFO  [BankingApplication] - $300 has been deposited to account ID 2 
INFO  [BankingApplication] - Transaction committed 
INFO  [BankingApplication] - Successfully transferred $300 from account ID 1 to account ID 2 
```

- For the `scenario 2` where 'Alice' tries to transfer $500 to Bob's account, the transaction is expected to fail as 'Alice' has insufficient balance

```
----------------------------------------- Scenario 2--------------------------------------------- 
INFO  [BankingApplication] - Again try to transfer $500 from Alice's account to Bob's account 
INFO  [BankingApplication] - Expected: Transaction to fail as Alice now only has a balance of $200
INFO  [BankingApplication] - Initiating transaction 
INFO  [BankingApplication] - Transfering money from account ID 1 to account ID 2 
INFO  [BankingApplication] - Withdrawing money from account ID: 1 
INFO  [BankingApplication] - Checking balance for account ID: 1 
INFO  [BankingApplication] - Available balance in account ID 1: 200 
ERROR [BankingApplication] - Error while withdrawing the money: Error: Not enough balance 
```

- For the `scenario 3` where 'Bob' tries to transfer $500 to account ID 1234, the transaction is expected to fail as account ID 1234 does not exist

```
----------------------------------------- Scenario 3--------------------------------------------- 
[BankingApplication] - Try to transfer $500 from Bob's account to a non existing account ID 
INFO  [BankingApplication] - Expected: Transaction to fail as account ID of recipient is invalid 
INFO  [BankingApplication] - Initiating transaction 
INFO  [BankingApplication] - Transfering money from account ID 2 to account ID 1234 
INFO  [BankingApplication] - Withdrawing money from account ID: 2 
INFO  [BankingApplication] - $500 has been withdrawn from account ID 2 
INFO  [BankingApplication] - Depositing money to account ID: 1234 
INFO  [BankingApplication] - Verifying whether account ID 1234 exists 
ERROR [BankingApplication] - Error while depositing the money: Error: Account does not exist 
INFO  [BankingApplication] - Check balance for Bob's account 
INFO  [BankingApplication] - Available balance in account ID 2: 1300 
INFO  [BankingApplication] - You should see $1300 balance in Bob's account (NOT $800) 
INFO  [BankingApplication] - Explanation: 
When trying to transfer $500 from Bob's account to account ID 1234, initially $500 withdrew from 
Bob's account. But then the deposit operation failed due to an invalid recipient account ID; Hence, 
the TX failed and the withdraw operation rollbacked, which is in the same TX
```

### Writing unit tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'.  When writing the test functions the below convention should be followed.
* Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
    @test:Config
    function testCreateAccount() {
```

This guide contains unit test cases for each method implemented in `account_manager.bal` file.

To run the unit tests, go to the sample src directory and run the following command,

```
$ <SAMPLE_ROOT_DIRECTORY>/src$ ballerina test
```

To check the implementations of this test file, refer [database_utilities_test.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/src/BankingApplication/test/account_manager_test.bal).
