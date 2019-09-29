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

- **Create Accounts** : Create a new account by providing username
- **Verify Accounts** : Verify the existence of an account by providing the account Id
- **Check Balance**   : Check account balance
- **Deposit Money**   : Deposit money into an account
- **Withdraw Money**  : Withdraw money from an account
- **Transfer Money**  : Transfer money from one account to another account

Transferring money from one account to another account involves both operations withdrawal from the transferor and deposit to the transferee. 

Let's assume the transaction fails during the deposit operation. Now the withdrawal operation carried out prior to 
deposit operation also needs to be rolled-back. Otherwise, we will end up in a state where transferor loses money. 
Therefore, to ensure the atomicity (all or nothing property), we need to perform the money transfer operation as a transaction. 

This example explains three different scenarios where one user tries to transfer money from his/her account to another user's account.
The first scenario shows a successful transaction whereas the other two fail due to different reasons.

## Prerequisites
- Ballerina Integrator
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina Integrator extension in [VSCode](https://code.visualstudio.com)
- [MySQL](https://dev.mysql.com/downloads/)
- [JDBC driver](https://dev.mysql.com/downloads/connector/j/)
    - Copy the downloaded JDBC driver jar file into the` <BALLERINA_HOME>/bre/lib` folder 

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping `Implementation` section.    

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

1. Create a project.
 ```bash
 $ ballerina new managing-database-transactions
 ```

 2. Move into the project directory and add a new module.
 ```bash
 $ ballerina add banking_application
 ```

 3. Add a ballerina.conf file and create bal files with meaningful names as shown in the project structure given below.
 ```shell
managing-database-transactions
├── Ballerina.toml
├── ballerina.conf
└── src
    └── banking_application
        ├── resources
        ├── Module.md
        ├── account_manager.bal
        ├── application.bal
        └── tests
            ├── account_manager_test.bal
            └── resources
```
4. Open the project with VS Code and write the integration implementation and tests in the `account_manager.bal`, `application.bal` and `account_manager_test.bal` files respectively.

5. The `transferMoney` function of `account_manager.bal` demonstrates how we can use transactions in Ballerina. It comprises of two different operations, withdrawal and deposit. To ensure that the transferring operation happens as a whole, it needs to reside in a database transaction block.
Transactions guarantee the 'ACID' properties. So if any of the withdrawal or deposit fails, the transaction will be aborted and all the operations carried out in the same transaction will be rolled back.
The transaction will be successful only when both, withdrawal from the transferor and deposit to the transferee are successful. 


## Testing 

### Before you begin
- Run the SQL script `database_initializer.sql` provided in the resources folder, to initialize the database and to create the required table.
```bash
   $mysql -u username -p <database_initializer.sql 
``` 

NOTE : You can find the SQL script [here](resources/database_initializer.sql).

- Add database configurations to the `ballerina.conf` file.
   - `ballerina.conf` file can be used to provide external configurations to the Ballerina programs. Since this guide needs MySQL database integration, a Ballerina configuration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
```
DATABASE_URL = "jdbc:mysql://127.0.0.1:3306/bankDB"
DATABASE_USERNAME = "root"
DATABASE_PASSWORD = "root"
```

- Navigate to the project directory and execute the following command in a terminal to run this sample.

```bash
   $ ballerina run --experimental banking_application
```

### Response you'll get

We created two user accounts for users 'Alice' and 'Bob'. Then initially we deposited $500 to Alice's account and $1000 to Bob's account.
Later we had three different scenarios to check the money transfer operation, which includes a database transaction. 

Let's now look at some important log statements we will get as the response for these three scenarios.

- For `Scenario 1` where 'Alice' transfers $300 to Bob's account, the transaction is expected to be successful.

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

- For `Scenario 2` where 'Alice' tries to transfer $500 to Bob's account, the transaction is expected to fail as 'Alice' has an insufficient balance.

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

- For `Scenario 3` where 'Bob' tries to transfer $500 to account ID 1234, the transaction is expected to fail as account ID 1234 does not exist.

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
- Test functions should be annotated with `@test:Config {}`. See the below example.
```ballerina
   @test:Config {}
   function testCreateAccount() {

   }
```
  
This guide contains unit tests for each method available in `account_manager.bal`.

To run the unit tests, navigate to the project directory and run the following command. 
```bash
   $ ballerina test --experimental
```
Please note that `--b7a.config.file=path/to/file` option is required if it is needed to read configurations from a ballerina configuration file

To check the implementation of the test file, refer to the [account_manager_test.bal](https://github.com/ballerina-guides/managing-database-transactions/blob/master/guide/banking_application/tests/account_manager_test.bal).
