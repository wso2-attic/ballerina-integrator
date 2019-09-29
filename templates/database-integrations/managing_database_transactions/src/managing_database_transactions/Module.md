# Managing Database Transactions

A transaction is a small unit of a program that must maintain Atomicity, Consistency, Isolation, and Durability − commonly known as ACID properties − in order to ensure accuracy, completeness, and data integrity. This template demonstrates managing database transactions using Ballerina. Please note that Ballerina transactions is an experimental feature. Please use --experimental flag when compiling Ballerina files which contain transaction related constructs.

> **Note:** Ballerina transactions is an experimental feature. Please use the `--experimental` flag when compiling Ballerina modules which contain transaction-related constructs.

Please use the guide documentation [Database Transactions](https://github.com/wso2/ballerina-integrator/tree/master/docs/content/src/learn/guides/database-integrations/managing-database-transactions) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Prerequisites
* [MySQL version 5.6 or later](https://www.mysql.com/downloads/)
* [Official JDBC driver](https://dev.mysql.com/downloads/connector/j/) for MySQL
* Use the database schema in `initializeDataBase.sql` file located inside `src/<module_name>/resources` directory to create a database.

## Running the Template
Create a directory called `lib` under the project root path and copy the `JDBC driver for MySQL` into it. Add the following in `Ballerina.toml` file to specify the driver.
```
[platform]
target = "java8"

    [[platform.libraries]]
    module = "module_name"
    path = "lib/mysql-connector-java-x.x.x.jar"
```

Configure the `ballerina.conf` file inside `src/<module_name>/resources` directory with relevant configuration.

Navigate to the project directory and build the Ballerina module using the following command. Path to the `ballerina.conf` file could be provided using the `--b7a.config.file` option.
```ballerina
ballerina build --experimental <module_name> --b7a.config.file=path/to/ballerina.conf/file
```

The build command would create an executable .jar file. Now run the .jar file created in the above step using the following command.
```ballerina    
java -jar target/bin/<module_name>.jar --b7a.config.file=path/to/ballerina.conf/file
```
