Template for Database-Backed Services using Ballerina

# Database-Backed Services using BallerinaP 

This is a template for the [Data-backed Service tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/database-integrations/data-backed-service/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `data_backed_service` template from Ballerina Central.

```
$ ballerina pull wso2/data_backed_service
```

Create a new project.

```bash
$ ballerina new data-backed-service
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/data_backed_service data_backed_service
```

This automatically creates data_backed_service service for you inside the `src` directory of your project.  

## Testing

### Before you begin
* Create a folder called `lib` under the project root path. Copy the [JDBC driver for MySQL](https://dev.mysql.com/downloads/connector/j/) into the `lib` folder.
* Download & run the SQL script `initializeDataBase.sql` provided inside the `resources` directory, to initialize the database and to create the required table.
```
   $mysql -u username -p <initializeDataBase.sql
```

- Add database configurations to the `ballerina.conf` file
   - `ballerina.conf` file can be used to provide external configurations to Ballerina programs. Since this guide needs MySQL database integration, a Ballerina configuration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
      ```
      DATABASE_URL = "jdbc:mysql://127.0.0.1:3306/EMPLOYEE_RECORDS"
      DATABASE_USERNAME = "root"
      DATABASE_PASSWORD = "root"
      ```

### Invoking the employee database service

Let’s build the module. Navigate to the project directory and execute the following command.

```
$ ballerina build data_backed_service
```

The build command would create an executable .jar file. Now run the .jar file created in the above step. Path to the ballerina.conf could be provided using the `--b7a.config.file` option.

```
$ java -jar target/bin/data_backed_service.jar --b7a.config.file=path/to/ballerina.conf/file
```

- Now you can test the functionality of the employee database management RESTFul service by sending HTTP requests for each database operation. For example, this guide uses the cURL commands to test each operation of the `employeeService` as follows.
