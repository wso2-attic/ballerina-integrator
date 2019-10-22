Template for Querying MySQL Databases using Ballerina

# Querying MySQL Databases using Ballerina

This is a template for the [Querying a MySQL Database tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/database-integrations/querying-mysql-database/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `querying_mysql_database` template from Ballerina Central.

```
$ ballerina pull wso2/querying_mysql_database
```

Create a new project.

```bash
$ ballerina new querying-mysql-database
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/querying_mysql_database querying_mysql_database
```

This automatically creates querying_mysql_database service for you inside the `src` directory of your project.  

## Testing

### Before you begin
* Create a folder called `lib` under the project root path. Copy the [JDBC driver for MySQL](https://dev.mysql.com/downloads/connector/j/) into the `lib` folder.
- Add these code segment to ballerina.toml file in the root directory

```ballerina
[platform]
target = "java8"
[[platform.libraries]]
module = "querying_mysql_database"
path = "./lib/mysql-connector-java-8.0.17.jar"
```

* Download & run the employees.sql script inside resources folder to create the table and insert data required for the guide.

* Add project configuration file by creating `ballerina.conf` file under the root path of the project structure. <br/>
This file should have the following MySQL database configurations.
```
MYSQL_URL = <jdbc_url><br/>
MYSQL_USERNAME = <mysql_username> <br/>
MYSQL_PASSWORD = <mysql_password> <br/>
```
### Invoking the service

Let’s build the module. While being in the querying_mysql_db directory, execute the following command.

```bash
$ ballerina build querying_mysql_database
```

The build command would create an executable .jar file. Now run the .jar file created in the above step.

```bash
$ java -jar target/bin/querying_mysql_database.jar
```

Now you can see the service is started on port 9095.
