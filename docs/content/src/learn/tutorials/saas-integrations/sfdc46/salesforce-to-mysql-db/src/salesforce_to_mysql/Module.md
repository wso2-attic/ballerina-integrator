Template for Salesforce to MySQL using Ballerina

# Salesforce to MySQL using Ballerina 

This is a template for [Salesforce to MySQL Database tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/sfdc46/salesforce-to-mysql-db/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `salesforce_to_mysql` template from Ballerina Central.

```
$ ballerina pull wso2/salesforce_to_mysql
```

Create a new project.

```bash
$ ballerina new salesforce-to-mysql-db
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add salesforce_to_mysql -t wso2/salesforce_to_mysql
```

This automatically creates salesforce_to_mysql service for you inside the `src` directory of your project.  

## Testing

### 1. Set up credentials for accessing Salesforce.

- Visit [Salesforce](https://www.salesforce.com) and create a Salesforce account.

- Create a connected app and obtain the following credentials:
    - Base URL (Endpoint)
    - Access Token
    - Client ID
    - Client Secret
    - Refresh Token
    - Refresh Token URL
    
#### 2. Create a database and set up credentials

- If you have not installed MySQL in your computer, Please install MySql on your local computer.
Visit [here](https://dev.mysql.com/downloads/) to download and install MySQL. After installing configure configure
a MySQL user and obtain username and password.

- Create a new database and create a new `contacts` table. You can use following SQL script to create the table
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

#### 3. Add JDBC client connector

Since we are using JDBC client for Database operations we need to create new directory called `lib` in the project
root directory and add `mysql-connector-java.jar` to the newly created `lib` directory. You can install
`mysql-connector-java.jar` from [here](https://dev.mysql.com/downloads/connector/j/). After that you should edit
your `Ballerina.toml` file and mentioned the path to `mysql-connector-java.jar` as follows.

```toml
[project]
org-name= "wso2"
version= "0.1.0"

[dependencies]

[platform]
target = "java8"

  [[platform.libraries]]
  module = "salesforce_to_mysql"
  path = "./lib/mysql-connector-java.jar"
```

#### 4. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure.
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

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build salesforce_to_mysql
```

This creates the executables. Now run the `salesforce_to_mysql.jar` file created in the above step.

```bash
$ java -jar target/bin/salesforce_to_mysql.jar
```

You will see the following log after successfully updating the database.

```
2019-09-26 17:41:27,708 INFO  [wso2/sfdc_to_mysql_db] - service started...
2019-09-26 17:41:32,094 INFO  [wso2/sfdc_to_mysql_db] - Batch job SFDC -> MySQL has been completed.
```
