# Managing Database Transactions

A transaction is a small unit of a program that must maintain Atomicity, Consistency, Isolation, and Durability − commonly known as ACID properties − in order to ensure accuracy, completeness, and data integrity. This template demonstrates managing database transactions using Ballerina. Please note that Ballerina transactions is an experimental feature. Please use --experimental flag when compiling Ballerina files which contain transaction related constructs.

Please use the guide documentation [Database Transactions](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/database-integrations/managing-database-transactions) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Prerequisites
* [MySQL version 5.6 or later](https://www.mysql.com/downloads/)
* [Official JDBC driver](https://dev.mysql.com/downloads/connector/j/) for MySQL
* Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder.
* Use the database schema in `initializeDataBase.sql` file located inside `src/<module_name>/resources` directory to create a database.

## Running the Template
Configure the ballerina.conf file inside `src/<module_name>/resources` directory with relevant configuration.

Execute the following Ballerina command from within the Ballerina project folder to run the managing database transactions template module.
```ballerina    
ballerina run --experimental <module_name> --b7a.config.file=<path_to_ballerina.conf_file>
```
