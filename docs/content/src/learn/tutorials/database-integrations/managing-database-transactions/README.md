# Database Transactions

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on managing database transactions using Ballerina. Please note that Ballerina transactions is an experimental feature. Please use `--experimental` flag when compiling Ballerina modules that contain transaction-related constructs. You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

A transaction is a small unit of a program that must maintain Atomicity, Consistency, Isolation, and Durability − 
commonly known as ACID properties − in order to ensure accuracy, completeness, and data integrity.

## What you’ll build 

To understand how you can manage database transactions using Ballerina, let’s consider a real-world use case of a simple banking application.

This banking application allows users to,

- **Create Accounts** : Create a new account by providing the username.
- **Verify Accounts** : Verify the existence of an account by providing the account Id.
- **Check Balance**   : Check the account balance.
- **Deposit Money**   : Deposit money into an account.
- **Withdraw Money**  : Withdraw money from an account.
- **Transfer Money**  : Transfer money from one account to another account.

Transferring money from one account to another account involves both operations withdrawal from the transferor and deposit to the transferee. 

Let's assume the transaction fails during the deposit operation. Now the withdrawal operation carried out prior to deposit operation also needs to be rolled-back. Otherwise, we will end up in a state where the transferor loses money. 
Therefore, to ensure the atomicity (all or nothing property), we need to perform the money transfer operation as a transaction. 

This example explains three different scenarios where one user tries to transfer money from his/her account to another user's account.

The first scenario shows a successful transaction whereas the other two fail due to different reasons.

<!-- INCLUDE_MD: ../../../../tutorial-prerequisites.md -->
- [MySQL](https://dev.mysql.com/downloads/)
- [JDBC driver](https://dev.mysql.com/downloads/connector/j/)

<!-- INCLUDE_MD: ../../../../tutorial-get-the-code.md -->

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping `Implementation` section.    

Create a project.
```bash
ballerina new managing-database-transactions
```

Navigate into the project directory and add a new module.
```bash
ballerina add managing_database_transactions
```

Create a folder called `lib` under the project root path. Copy the [JDBC driver for MySQL](https://dev.mysql.com/downloads/connector/j/) into the `lib` folder.

Add a `ballerina.conf` file and create .bal files with meaningful names as shown in the project structure given below.
```shell
managing-database-transactions
├── Ballerina.toml
├── ballerina.conf
├── lib
│    └── mysql-connector-java-x.x.x.jar
└── src
    └── managing_database_transactions
        ├── resources
        ├── Module.md
        ├── account_manager.bal
        ├── application.bal
        └── tests
            ├── account_manager_test.bal
            └── resources
```
Open the project with VS Code and write the integration implementation and tests in the `account_manager.bal`, `application.bal`, and `account_manager_test.bal` files respectively.

The `transferMoney` function of `account_manager.bal` demonstrates how we can use transactions in Ballerina. It comprises of two different operations; withdrawal and deposit. To ensure that the transferring operation happens as a whole, it needs to reside in a database transaction block.

Transactions guarantee the 'ACID' properties. So if any of the withdrawal or deposit operations fail, the transaction will be aborted and all the operations carried out in the same transaction will be rolled back.
The transaction will be successful only when both withdrawal from the transferor and deposit to the transferee are successful. 

## Testing 

### Before you begin
- Run the SQL script `database_initializer.sql` provided in the resources directory, to initialize the database and to create the required table.
```bash
   $mysql -u username -p <database_initializer.sql 
```

- Add database configurations to the `ballerina.conf` file.
   - `ballerina.conf` file can be used to provide external configurations to Ballerina programs. Since this guide needs MySQL database integration, a Ballerina configuration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
```
DATABASE_URL = "jdbc:mysql://127.0.0.1:3306/bankDB"
DATABASE_USERNAME = "root"
DATABASE_PASSWORD = "root"
```

Let’s build the module. Navigate to the project directory and execute the following command.
```
$ ballerina build --experimental managing_database_transactions
 ```

The build command would create an executable .jar file. Now run the .jar file created in the above step. Path to the `ballerina.conf` could be provided using the `--b7a.config.file` option.

```bash
java -jar target/bin/managing_database_transactions.jar --b7a.config.file=path/to/ballerina.conf/file
```

### Response you'll get

We created two user accounts for users 'Alice' and 'Bob'. Then initially we deposited $500 to Alice's account and $1000 to Bob's account.
Later we had three different scenarios to check the money transfer operation, which includes a database transaction. 

Let's now look at some important log statements we will get as the response for these three scenarios.

- For `Scenario 1` where 'Alice' transfers $300 to Bob's account, the transaction is expected to be successful

```
------------------------------------ Scenario 1---------------------------------------- 
INFO  [managing_database_transactions] - Transfer $300 from Alice's account to Bob's account
INFO  [managing_database_transactions] - Expected: Transaction to be successful
INFO  [managing_database_transactions] - Initiating transaction
INFO  [managing_database_transactions] - Verifying whether account ID 1 exists
INFO  [managing_database_transactions] - Available balance in account ID 1: 500
INFO  [managing_database_transactions] - Withdrawing money from account ID: 1
INFO  [managing_database_transactions] - $300 has been withdrawn from account ID 1
INFO  [managing_database_transactions] - Verifying whether account ID 2 exists
INFO  [managing_database_transactions] - Depositing money to account ID: 2
INFO  [managing_database_transactions] - $300 has been deposited to account ID 2
INFO  [managing_database_transactions] - Transaction committed
INFO  [managing_database_transactions] - Successfully transferred $300 from account ID 1 to account ID
```

- For `Scenario 2` where 'Alice' tries to transfer $500 to Bob's account, the transaction is expected to fail as 'Alice' has an insufficient balance

```
------------------------------------ Scenario 2---------------------------------------- 
INFO  [managing_database_transactions] - Again try to transfer $500 from Alice's account to Bob's account
INFO  [managing_database_transactions] - Expected: Transaction to fail as Alice now only has a balance of $200 in account
INFO  [managing_database_transactions] - Initiating transaction
INFO  [managing_database_transactions] - Verifying whether account ID 1 exists
INFO  [managing_database_transactions] - Available balance in account ID 1: 200
ERROR [managing_database_transactions] - Error while withdrawing the money: Error: Not enough balance
ERROR [managing_database_transactions] - Failed to transfer money from account ID 1 to account ID 2
INFO  [managing_database_transactions] - Transaction aborted
```

- For `Scenario 3` where 'Bob' tries to transfer $500 to account ID 1234, the transaction is expected to fail as account ID 1234 does not exist

```
------------------------------------ Scenario 3---------------------------------------- 
INFO  [managing_database_transactions] - Try to transfer $500 from Bob's account to a non existing account ID
INFO  [managing_database_transactions] - Expected: Transaction to fail as account ID of the recipient is invalid
INFO  [managing_database_transactions] - Initiating transaction
INFO  [managing_database_transactions] - Verifying whether account ID 2 exists
INFO  [managing_database_transactions] - Available balance in account ID 2: 1300
INFO  [managing_database_transactions] - Withdrawing money from account ID: 2
INFO  [managing_database_transactions] - $500 has been withdrawn from account ID 2
INFO  [managing_database_transactions] - Verifying whether account ID 1234 exists
ERROR [managing_database_transactions] - Error while depositing the money: Error: Account does not exist
ERROR [managing_database_transactions] - Failed to transfer money from account ID 2 to account ID 1234
INFO  [managing_database_transactions] - Check balance for Bob's account
INFO  [managing_database_transactions] - Verifying whether account ID 2 exists
INFO  [managing_database_transactions] - Available balance in account ID 2: 1300
INFO  [managing_database_transactions] - You should see $1300 balance in Bob's account (NOT $800)
INFO  [managing_database_transactions] - Explanation:
When trying to transfer $500 from Bob's account to account ID 1234, initially $500
was withdrawn from Bob's account. But then the deposit operation failed due to an invalid
recipient account ID; Hence, the transaction failed and withdraw operation rollbacked as 
it is in the same transaction
```
