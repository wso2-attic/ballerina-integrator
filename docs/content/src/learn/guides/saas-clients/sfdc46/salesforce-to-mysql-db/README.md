# Salesforce to MySQL Database

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the 
support of connectors. In this guide, we are mainly focusing on using batch processing to synchronize Salesforce data
with a MySQL Database.

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and 
describe SObjects and organizational data through the Salesforce REST API. Also it supports insert, upsert, update, 
query, and delete operations for CSV, JSON, and XML data types that are available in Salesforce bulk API. It handles 
OAuth 2.0 authentication.

Ballerina provides standardized interface for accessing any relational database via JDBC. This allows you to run 
diverse SQL operations on a database, including Select, Insert, Update, and Delete.

You can find other integration modules from [wso2-ballerina](https://github.com/wso2-ballerina) GitHub organization.

## What you'll build

This application queries Salesforce for new or updated contacts at a regular interval. Then it processes SOQL records 
one at a time. It queries the database using JDBC client to check whether the Salesforce contact exists in the 
database. If it currently exists in the database, update the existing account in the database. Alternately, insert the 
new contact into the database. After the process is completed for the entire Salesforce accounts batch, a success 
message is logged.

![sfdc to mysql database](../../../../../../assets/img/salesforce-to-mysql-database.jpg)

## Prerequisites

- [Java](https://www.oracle.com/technetwork/java/index.html)
- A Text Editor or an IDE
    > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: 
[VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), 
[IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- Link to download Ballerina Integrator.

## Implementation

A Ballerina project needs to be created for the integration use case explained above. Please follow the steps given below 
to create the project and modules. You can learn about the Ballerina project and modules in this 
[guide](https://ei.docs.wso2.com/en/latest/ballerina-integrator/develop/using-modules/#creating-a-project).

1. Create a new project.

    ```bash
    $ ballerina new salesforce-to-mysql-db
    ```

2. Create a module.

    ```bash
    $ ballerina add sfdc_to_mysql_db
    ```

   The project structure is created as indicated below.

    ```
    salesforce-to-mysql-db
    ├── Ballerina.toml
    └── src
        └── sfdc_to_mysql_db
            ├── Module.md
            ├── main.bal
            ├── resources
            └── tests
                └── resources
    ```

3. Set up credentials for accessing Salesforce.
   
   i. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce account.

   ii. Create a connected app and obtain the following credentials: 
    - Base URL (Endpoint)
    - Access Token
    - Client ID
    - Client Secret
    - Refresh Token
    - Refresh Token URL

    > **Note**: When you are setting up the connected app, select the following scopes under **Selected OAuth Scopes**:
    - Access and manage your data (api)
    - Perform requests on your behalf at any time (refresh_token, offline_access)
    - Provide access to your data via the Web (web)

   iii. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
      obtaining OAuth2 credentials, see the 
      [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

4. Create a database and set up credentials

    i. If you have not installed MySQL in your computer, Please install MySql on your local computer. 
    Visit [here](https://dev.mysql.com/downloads/) to download and install MySQL. After installing configure configure 
    a MySQL user and obtain username and password.

    ii. Create a new database and create a new `contacts` table. You can use following SQL script to create the table 
    and insert a data row in to the table.
    ```SQL
    USE sf_company;
    CREATE TABLE IF NOT EXISTS contacts (
        email varchar(255) NOT NULL,
        first_name varchar(255) NOT NULL,
        last_name varchar(255) NOT NULL,
        last_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (email)
    );
    INSERT INTO contacts VALUES ("johndoe@wso2.com", "John", "Doe", CURRENT_TIMESTAMP);
    ```
5. Since we are using JDBC client for Database operations we need to create new directory called `lib` in the project
   root directory and add `mysql-connector-java.jar` to the newly created `lib` directory. You can install 
   `mysql-connector-java.jar` from [here](https://dev.mysql.com/downloads/connector/j/). After that you should edit 
   your `Ballerina.toml` file and mentioned the path to `mysql-connector-java.jar` as follows.

    **Ballerina.toml**
    ```toml
    [project]
    org-name= "wso2"
    version= "0.1.0"
    
    [dependencies]
    
    [platform]
    target = "java8"
    
      [[platform.libraries]]
      module = "guide"
      path = "./lib/mysql-connector-java.jar"
    ```

6. Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
   This file should have following configurations. Add the obtained Salesforce configurations and Database 
   configurations to the file.

    ```
    SF_BASE_URL="<Salesforce base url (eg: https://ap15.salesforce.com)>"
    SF_ACCESS_TOKEN="<Salesforce access token>"
    SF_CLIENT_ID="<Salesforce client ID>"
    SF_CLIENT_SECRET="<Salesforce client secret>"
    SF_REFRESH_URL="<Salesforce refresh url (eg: https://login.salesforce.com/services/oauth2/token)>"
    SF_REFRESH_TOKEN="<Salesforce refresh token>"
    JDBC_URL="<JDBC URL (eg: jdbc:mysql://localhost:3306/sf_company)>"
    DB_USERNAME="<MySQL database username>"
    DB_PASSWORD="<MySQL database password>"
    SCHEDULER_INTERVAL_IN_MILLIS=<Scheduler interval in milli-seconds (eg: 60000)>
    ```

7. Open the project with VS Code. The integration implementation is written in the `src/sfdc_to_mysql_db/main.bal` 
   file.

    **main.bal**
    <!-- INCLUDE_CODE: src/guide/main.bal -->

    Here we are running `sfdcToMysqlService` using a task scheduler. You can set the Scheduler interval in the 
    `ballerina.conf` file. When the `sfdcToMysqlService` service's `onTrigger` function is triggered, it will retrieve 
    newly modified Salesforce contacts and update the database using them.

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build guide
```

This creates the executables. Now run the `guide.jar` file created in the above step.

```bash
$ java -jar target/bin/guide.jar
```

You will see the following log after successfully updating the database.

```
2019-09-26 17:41:27,708 INFO  [wso2/sfdc_to_mysql_db] - service started... 
2019-09-26 17:41:32,094 INFO  [wso2/sfdc_to_mysql_db] - Batch job SFDC -> MySQL has been completed.
```
