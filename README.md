# Database Backed RESTful Web Service
This guide walks you through building a database-backed RESTful web service with Ballerina.

## <a name="what-you-build"></a>  What you'll build
You'll build an employee data management web service that performs CRUD Operations(Create, Read, Update, Delete) on MySQL database. The service will have following functionalities,
* Add new employees to the database via HTTP POST method
* Retrieve existing employee details from the database via HTTP GET method
* Update existing employee in the database via HTTP PUT method
* Delete existing employee from the database via HTTP DELETE method

Basically, this service will deal with MySQL database and expose the data operations as a web service.
Please refer to the following scenario diagram to understand the complete end-to-end scenario.


![alt text](https://github.com/rosensilva/ballerina-samples/blob/master/bellerinaDataBackedApiSample/images/database_service_scenario.png)


## <a name="pre-req"></a> Prerequisites
 
* JDK 1.8 or later
* Ballerina Distribution (Install Instructions:  https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
* MySQL version 5.6 or better
* Official JDBC driver for MySQL ( Download https://dev.mysql.com/downloads/connector/j/)
  * Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder 
* A Text Editor or an IDE


Optional Requirements
- Docker (Follow instructions in https://docs.docker.com/engine/installation/)
- Ballerina IDE plugins. ( IntelliJ IDEA, VSCode, Atom)
- Testerina (Refer: https://github.com/ballerinalang/testerina)
- Container-support (Refer: https://github.com/ballerinalang/container-support)
- Docerina (Refer: https://github.com/ballerinalang/docerina)

## <a name="develop-app"></a> Develop the application
### Before you begin
##### Create the database
Go to the terminal (command Prompt in Microsoft Windows). Open MySQL client by entering the following command

```bash
$ mysql -u root -p
```
Then create a database named as `RECORDS` by entering following command in mysql
```mysql
mysql> CREATE DATABASE RECORDS;
```

##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
├── employeeService
│   |── util
│   |    └── db
│   |        ├── employee_database_util.bal
│   |        └── employee_database_util_test.bal
│   ├── employee_database_service.bal
│   └── employee_database_service_test.bal
└── ballerina.conf

```
##### Add database configurations to the `ballerina.conf` file
The purpose of  `ballerina.conf` file is to provide any external configurations that are needed for ballerina programs. Since this guide has MySQL database integration, we need to provide the database connection properties to the ballerina program via `ballerina.cof` file.
This configuration file will have the following fields,
```
DATABASE_HOST = localhost
DATABASE_PORT = 3306
DATABASE_USERNAME = username
DATABASE_PASSWORD = password
DATABASE_NAME = RECORDS
```
First, you need to replace `localhost`, `3306`, `username`, `password` the respective MySQL database connection properties in the `ballerina.conf` file. You can keep the DATABASE_NAME as it is if you don't want to change the name explicitly.


### Develop the Ballerina web service
Ballerina language has built-in support for writing web services. The `service` keyword in ballerina simply defines a web service. Inside the service block, we can have all the required resources. You can define a resource using `resource` keyword in Ballerina. We can implement the business logic inside a resource block using Ballerina language syntaxes. The following ballerina code is the complete service with resources to add, retrieve, update and delete employee data.

```ballerina
package employeeService;

import ballerina.config;
import ballerina.log;
import ballerina.net.http;
import employeeService.util.db as databaseUtil;

service<http> records {
    string dbHost = config:getGlobalValue("DATABASE_HOST");
    string dbPort = config:getGlobalValue("DATABASE_PORT");
    string userName = config:getGlobalValue("DATABASE_USERNAME");
    string password = config:getGlobalValue("DATABASE_PASSWORD");
    string dbName = config:getGlobalValue("DATABASE_NAME");

    boolean isInitialized = databaseUtil:initializeDatabase(dbHost, dbPort, userName, password, dbName);

    @http:resourceConfig {
        methods:["POST"],
        path:"/employee/"
    }
    resource addEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        // Convert the json payload to string values
        var name, nameError = (string)requestPayload.Name;
        var age, ageError = (string)requestPayload.Age;
        var ssn, ssnError = (string)requestPayload.SSN;
        var employeeId, empIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Invoke insertData function to store data in the MySQL database
        json updateStatus = databaseUtil:insertData(name, age, ssn, employeeId);
        log:printInfo("New employee added to database: employeeID = " + employeeId);

        // Send the response back to the client with the status of the database operation
        json respJson = {"Name":name, "Age":age, "SSN":ssn, "EmployeeID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/employee/"
    }
    resource retrieveEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        map queryParams = request.getQueryParams();
        var employeeId, employeeIdError = (string)queryParams.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Invoke retrieveById function to retrieve data from MySQL database
        json employeeData = databaseUtil:retrieveById(employeeId);

        // Send the response back to the client with the employee data
        response.setJsonPayload(employeeData);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["PUT"],
        path:"/employee/"
    }
    resource updateEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        // Convert the json payload to string values
        var name, nameError = (string)requestPayload.Name;
        var age, ageError = (string)requestPayload.Age;
        var ssn, ssnError = (string)requestPayload.SSN;
        var employeeId, employeeIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Invoke updateData function to update data in MySQL database
        json updateStatus = databaseUtil:updateData(name, age, ssn, employeeId);
        log:printInfo("Employee details updated in database: EmployeeID = " + employeeId);

        // Send the response back to the client with database update status
        json respJson = {"Name":name, "Age":age, "SSN":ssn, "EmployeeID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["DELETE"],
        path:"/employee/"
    }
    resource deleteEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        var employeeId, employeeIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Invoke deleteData function to delete data from MySQL database
        json updateStatus = databaseUtil:deleteData(employeeId);
        log:printInfo("Employee deleted from database: EmployeeID = " + employeeId);

        // Send the response back to the client with status of SQL delete operation
        json respJson = {"Employee ID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }
}
```

Please refer `ballerina-guides/data-backed-service/employeeService/employee_database_service.bal` file for the complete implementaion of employee management web service.


### Develop the database handling utility functions
You can implement custom functions in Ballerina which does specific tasks. For this scenario, we need to have utility functions that deal with MySQL database. The following code is the implementation of the database utility package.
```ballerina 
package employeeService.util.db;

import ballerina.data.sql;

sql:ClientConnector sqlConnection;

public function initializeDatabase (string dbHost, string dbPort, string userName, string password, string dbName)
(boolean) {
    // Convert dbPort string to integer value
    var dbPortNumber, _ = <int>dbPort;
    dbName = dbName + "?useSSL=false";
    // Initialize the global variable "sqlConnection" with MySQL database connection
    sqlConnection = create sql:ClientConnector(sql:DB.MYSQL, dbHost, dbPortNumber, dbName, userName, password,
                                               {maximumPoolSize:5});
    // Create the employee database table by invoking createTable function
    _ = createTable();
    return true;
}

public function createTable () (int) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Create table by invoking update action defined in ballerina sql connector
    string sqlString = "CREATE TABLE IF NOT EXISTS EMPLOYEES (EmployeeID INT, Name VARCHAR
                       (50), Age INT, SSN INT, PRIMARY KEY (EmployeeID))";
    int updateRowCount = employeeDataBase.update(sqlString, null);
    return updateRowCount;
}

public function insertData (string name, string age, string ssn, string employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Inserted"};

    string sqlString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES ('" + name + "','" + age + "','" +
                       ssn + "','" + employeeId + "')";
    // Insert data to SQL database by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Inserted Successfully"};
    }
    return updateStatus;
}

public function updateData (string name, string age, string ssn, string employeeId) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Updated"};

    string sqlString = "UPDATE EMPLOYEES SET Name = '" + name + "', Age = '" + age + "', SSN = '" + ssn + "'WHERE
                        EmployeeID  = '" + employeeId + "'";
    // Update existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Updated Successfully"};
    }
    return updateStatus;
}

public function deleteData (string employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {"Status":"Data Not Deleted"};

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = '" + employeeID + "'";
    // Delete existing data by invoking update action defined in ballerina sql connector
    int updateRowCount = employeeDataBase.update(sqlString, null);

    // Check the MySQL updated row count to set the status
    if (updateRowCount > 0) {
        updateStatus = {"Status":"Data Deleted Successfully"};
    }
    return updateStatus;
}

public function retrieveById (string employeeID) (json) {
    endpoint<sql:ClientConnector> employeeDataBase {
        sqlConnection;
    }
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = '" + employeeID + "'";
    // Retrieve employee data by invoking call action defined in ballerina sql connector
    var dataTable = employeeDataBase.call(sqlString, null, null);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue, _ = <json>dataTable;
    return jsonReturnValue;
}
```

The `endpoint` keyword in ballerina refers to a connection with remote service, in this case, the remote service is MySQL database. `employee database` is the reference name for the SQL endpoint. This endpoint is initialized with the  SQL connection. The rest of the code is just preparing SQL queries and executing them by calling `update` action in `ballerina.data.sql` package. finally, the status of the SQL operation is returned as a JSON file.



## <a name="testing"></a> Testing 

### <a name="invoking"></a> Invoking the RESTful service 

You can run the RESTful service that you developed above, in your local environment. You need to have the Ballerina installation on your local machine and simply point to the <ballerina>/bin/ballerina binary to execute all the following steps.  

1. As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory structure of the service that we developed above and it will create an executable binary out of that. 

```
$ballerina build  /employeeService
```

2. Once the employeeService.balx is created, you can run that with the following command. 

```
ballerina run employeeService.balx 
```

3. The successful execution of the service should show us the following output. 
```
ballerina: deploying service(s) in 'employeeService'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
 
```

4. You can test the functionality of the employee database management RESTFul service by sending HTTP request for each database operation. For example, we have used the curl commands to test each operation of employeeService as follows. 

**Add new employee** 
```
curl -v -X POST -d '{"Name":"Alice", "Age":"20","SSN":"123456789","EmployeeID":"1"}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output :  
< HTTP/1.1 200 OK
{"Name":"Alice","Age":"20","SSN":"123456789","EmployeeID":"1","Status": \
{"Status":"Data Inserted Successfully"}}
```

**Retrieve employee data** 
```
curl -v  "http://localhost:9090/records/employee?EmployeeID=1"

Output : 
< HTTP/1.1 200 OK
[{"EmployeeID":1,"Name":"Alice","Age":20,"SSN":123456789}]

```
**Update an existing employee data** 
```
curl -v -X PUT -d '{"Name":"Alice Updated", "Age":"30","SSN":"123456789","EmployeeID":"1"}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output: 
< HTTP/1.1 200 OK
{"Name":"Alice Updated","Age":"30","SSN":"123456789","EmployeeID":"1","Status": \
{"Status":"Data Updated Successfully"}}
```

**Delete employee data** 
```
curl -v -X DELETE -d '{"EmployeeID":"1"}'  "http://localhost:9090/records/employee" \
-H "Content-Type:application/json"

Output:
< HTTP/1.1 200 OK
{"Employee ID":"1","Status":{"Status":"Data Deleted Successfully"}}
```

### <a name="unit-testing"></a> Writing Unit Tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g.: testAddEmployee()

This guide contains unit test cases in the respective folders. The two test cases are written to test the Employee Data Service and the Database utilities package.
To run the unit tests, go to the sample root directory and run the following command
```bash
$ ballerina test employeeService/
```


## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying Locally
You can deploy the RESTful service that you developed above, in your local environment. You can use the Ballerina executable archive (.balx) archive that we created above and run it in your local environment as follows. 

```
ballerina run employeeService.balx 
```


### <a name="deploying-on-docker"></a> Deploying on Docker
(Work in progress) 

### <a name="deploying-on-k8s"></a> Deploying on Kubernetes
(Work in progress) 


## <a name="observability"></a> Observability 

### <a name="logging"></a> Logging
(Work in progress) 

### <a name="metrics"></a> Metrics
(Work in progress) 


### <a name="tracing"></a> Tracing 
(Work in progress) 
