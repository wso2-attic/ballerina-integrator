# Data Backed Service

Data inside a database can be exposed to the outside world by using a database backed RESTful web service. RESTful API calls enable you to add, view, update, and remove data stored in a database from the outside world. This template demonstrates on building a database-backed RESTful web service with Ballerina.

Please use the guide documentation [Database Interaction](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/database-integrations/data-backed-service) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Prerequisites
* [MySQL version 5.6 or later](https://www.mysql.com/downloads/)
* [Official JDBC driver](https://dev.mysql.com/downloads/connector/j/) for MySQL
* Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder.
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
Configure the ballerina.conf file inside `src/<module_name>/resources` directory with relevant configuration.

Execute the following Ballerina command from within the Ballerina project folder to run the data backed service template module.
```ballerina    
ballerina run <module_name> --b7a.config.file=<path_to_ballerina.conf_file>
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
