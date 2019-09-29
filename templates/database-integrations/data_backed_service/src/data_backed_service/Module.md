# Data Backed Service

Data inside a database can be exposed to the outside world by using a database backed RESTful web service. RESTful API calls enable you to add, view, update, and remove data stored in a database from the outside world. This template demonstrates on building a database-backed RESTful web service with Ballerina.

Please use the guide documentation [Database Interaction](https://github.com/wso2/ballerina-integrator/tree/master/docs/content/src/learn/guides/database-integrations/data-backed-service) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Prerequisites
* [MySQL version 5.6 or later](https://www.mysql.com/downloads/)
* [Official JDBC driver](https://dev.mysql.com/downloads/connector/j/) for MySQL
* Use the following database schema to store details related to the template. Find the `initializeDataBase.sql` file located inside the `src/<module_name>/resources` folder.
```
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| EmployeeID | int         | NO   | PRI | NULL    |       |
| Name       | varchar(50) | YES  |     | NULL    |       |
| Age        | int         | YES  |     | NULL    |       |
| SSN        | int         | YES  |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+
```

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
ballerina build <module_name> --b7a.config.file=path/to/ballerina.conf/file
```

The build command would create an executable .jar file. Now run the .jar file created in the above step using the following command.
```ballerina    
java -jar target/bin/<module_name>.jar --b7a.config.file=path/to/ballerina.conf/file
```

Invoke services with the following requests. Use an HTTP client like cURL.
* **Adding a record**
```
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"
```
Sample Output:
``` 
{"Status":"Data Inserted Successfully"}
```
* **Retrieving a record**
```
curl -v  "http://localhost:9090/records/employee/1"
```
Sample Output: 
```
[{"EmployeeID":1,"Name":"Alice","Age":20,"SSN":123456789}]
```
* **Updating a record**
```
curl -v -X PUT -d '{"name":"Alice Updated", "age":30,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"
```
Sample Output:
``` 
{"Status":"Data Updated Successfully"}
```
* **Deleting a record**
```
curl -v -X DELETE "http://localhost:9090/records/employee/1"
```
Sample Output:
```
{"Status":"Data Deleted Successfully"}
```
