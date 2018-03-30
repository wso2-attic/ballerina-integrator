# Database Backed RESTful Web Service

Data inside a database can be exposed to the outside world by using a database backed RESTful web service. RESTful API calls enable you to add, view, update, and remove data stored in a database from the outside world.

> This guide walks you through building a database-backed RESTful web service with Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the RESTFul service with circuit breaker](#develop-app)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
- [Observability](#observability)

## <a name="what-you-build"></a>  What you'll build

You'll build an employee data management web service that performs CRUD Operations (Create, Read, Update, Delete) on the MySQL database.  Also, this guide walks you through the process of accessing relational data via the Ballerina language. The service will have following functionalities.

* Add new employees to the database via HTTP POST method
* Retrieve an existing employee details from the database via HTTP GET method
* Update an existing employee in the database via HTTP PUT method
* Delete an existing employee from the database via HTTP DELETE method

Basically, this service will deal with a MySQL database and expose the data operations as a web service. Refer to the following scenario diagram to understand the complete end-to-end scenario.


![alt text](/images/database_service_scenario2.png)


## <a name="pre-req"></a> Prerequisites
 
* JDK 1.8 or later
* [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
* MySQL version 5.6 or better
* Official JDBC driver for MySQL ( Download https://dev.mysql.com/downloads/connector/j/)
  * Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder 
* A Text Editor or an IDE


**Optional requirements**
- [Docker](https://docs.docker.com/engine/installation/)
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))

## <a name="develop-app"></a> Developing the SQL data backed web service
### Before you begin
#### Create the database
Navigate to the command line and open the MySQL client by entering the following command.**

```bash
$ mysql -u root -p
```
#### Create the tables

Then create a table named as `EMPLOYEES` by entering the following command in MySQL.
```mysql
mysql> CREATE TABLE IF NOT EXISTS EMPLOYEES (EmployeeID INT, Name VARCHAR
                       (50), Age INT, SSN INT, PRIMARY KEY (EmployeeID))
```

#### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
├── ballerina.conf
└── data_backed_service
    ├── employee_db_service.bal
    └── test
        └── employee_db_service_test.bal


```
#### Add database configurations to the `ballerina.conf` file
You can use `ballerina.conf` file to provide external configurations to Ballerina programs. Since this guide has MySQL database integration, you need to provide the database connection properties to the Ballerina program via the `ballerina.conf` file.
This configuration file will have the following fields.
```
DATABASE_HOST = localhost
DATABASE_PORT = 3306
DATABASE_USERNAME = username
DATABASE_PASSWORD = password
DATABASE_NAME = EMPLOYEE_RECORDS
```
First, you need to replace `localhost`, `3306`, `username`, and `password`, which are the respective MySQL database connection properties in the `ballerina.conf` file. You can keep the DATABASE_NAME as it is if you do not want to change the name explicitly.

### Implementation of the Ballerina web service
Ballerina language has built-in support for writing web services. The `service` keyword in Ballerina simply defines a web service. Inside the service block, we can have all the required resources. You can define a resource inside the service. You can implement the business logic inside a resource using Ballerina language syntaxes. The following Ballerina code is the employee data service with resources to add, retrieve, update and delete employee data.

```ballerina
package data_backed_service;

import ballerina/data.sql;
import ballerina/log;
import ballerina/mime;
import ballerina/net.http;

struct Employee {
    string name;
    int age;
    int ssn;
    int employeeId;
}

// Create SQL endpoint to MySQL database
endpoint sql:Client employeeDB {
    database:sql:DB.MYSQL,
    host:"localhost",
    port:3306,
    name:"EMPLOYEE_RECORDS",
    username:"root",
    password:"qwe123",
    options:{maximumPoolSize:5}
};

endpoint http:ServiceEndpoint listener {
    port:9090
};

@http:ServiceConfig {
    basePath:"/records"
}
service<http:Service> employee_data_service bind listener {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/employee/"
    }
    addEmployeeResource (endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response = {};
        Employee employeeData = {};
        // Extract the data from the request payload
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData =? <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            return;
        }

        // Invoke insertData function to save data in the MySQL database
        json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn, employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/employee/{employeeId}"
    }
    retrieveEmployeeResource (endpoint httpConnection, http:Request request, string employeeId) {
        // Initialize an empty http response message
        http:Response response = {};
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
            // Invoke retrieveById function to retrieve data from MySQL database
                var employeeData = retrieveById(empID);
                // Send the response back to the client with the employee data
                response.setJsonPayload(employeeData);
                _ = httpConnection -> respond(response);
            }
            error err => {
            //Check path parameter errors and send bad request message to client
                response.setStringPayload("Error : Please enter a valid employee ID ");
                response.statusCode = 400;
                _ = httpConnection -> respond(response);
            }
        }
    }

    @http:ResourceConfig {
        methods:["PUT"],
        path:"/employee/"
    }
    updateEmployeeResource (endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response = {};
        Employee employeeData = {};
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData =? <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            return;
        }

        // Invoke updateData function to update data in MySQL database
        json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn, employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/employee/{employeeId}"
    }
    deleteEmployeeResource (endpoint httpConnection, http:Request request, string employeeId) {
        // Initialize an empty http response message
        http:Response response = {};
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
            // Invoke deleteData function to delete the data from MySQL database
                var deleteStatus = deleteData(empID);
                // Send the response back to the client with the employee data
                response.setJsonPayload(deleteStatus);
                _ = httpConnection -> respond(response);
            }
            error err => {
            //Check path parameter errors and send bad request message to client
                response.setStringPayload("Error : Please enter a valid employee ID ");
                response.statusCode = 400;
                _ = httpConnection -> respond(response);
            }
        }
    }
}

public function insertData (string name, int age, int ssn, int employeeId) returns (json) {

    json updateStatus;
    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
    sql:Parameter para3 = {sqlType:sql:Type.INTEGER, value:ssn};
    sql:Parameter para4 = {sqlType:sql:Type.INTEGER, value:employeeId};
    sql:Parameter[] params = [para1, para2, para3, para4];
    string sqlString = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, params);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Inserted Successfully"};
        }
        sql:SQLConnectorError err => {
            updateStatus = {"Status":"Data Not Inserted", "Error":err.message};
        }
    }
    return updateStatus;
}

public function retrieveById (int employeeID) returns (json) {

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:employeeID};
    sql:Parameter[] params = [para1];
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select action defined in ballerina sql connector
    table dataTable =? employeeDB -> select(sqlString, params, null);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue =? <json>dataTable;
    return jsonReturnValue;
}

public function updateData (string name, int age, int ssn, int employeeId) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
    sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
    sql:Parameter para3 = {sqlType:sql:Type.INTEGER, value:ssn};
    sql:Parameter para4 = {sqlType:sql:Type.INTEGER, value:employeeId};
    sql:Parameter[] params = [para1, para2, para3, para4];
    string sqlString = "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, params);
    match ret {
        int updateRowCount => {
            if (updateRowCount > 0) {
                updateStatus = {"Status":"Data Updated Successfully"};
            }
            else {
                updateStatus = {"Status":"Data Not Updated"};
            }
        }
        sql:SQLConnectorError err => {
            updateStatus = {"Status":"Data Not Updated", "Error":err.message};
        }
    }
    return updateStatus;
}

public function deleteData (int employeeID) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:employeeID};
    sql:Parameter[] params = [para1];
    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, params);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Deleted Successfully"};
        }
        sql:SQLConnectorError err => {
            updateStatus = {"Status":"Data Not Deleted", "Error":err.message};
        }
    }
    return updateStatus;
}
```

Please refer to the `ballerina-guides/data-backed-service/src/data_backed_service/employee_db_service.bal` file for the complete implementaion of the employee management web service.


You can implement custom functions in Ballerina that do specific tasks. For this scenario, you need to have functions to deal with the MySQL database.

The `endpoint` keyword in Ballerina refers to a connection with a remote service. In this case, the remote service is a MySQL database. `employeeDB` is the reference name for the SQL endpoint. The endpoint is initialized with an SQL connection. The rest of the code is just preparing SQL queries and executing them by calling the `update` action in the `ballerina/data.sql` package. Finally, the status of the SQL operation is returned as a JSON file.

## <a name="testing"></a> Testing 

### <a name="invoking"></a> Invoking the RESTful service 

You can run the RESTful service that you developed above, in your local environment. You need to have the Ballerina installation on your local machine and simply point to the <ballerina>/bin/ballerina binary to execute all the following steps.  

1. As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory structure of the service that we developed above and it will create an executable binary out of that. 

```
$ ballerina build  /data_backed_service
```

2. Once the data_backed_service.balx is created, you can run that with the following command. 

```
$ ballerina run data_backed_service.balx 
```

3. The successful execution of the service should show us the following output. 
```
ballerina: deploying service(s) in 'data_backed_service'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
 
```

4. You can test the functionality of the employee database management RESTFul service by sending HTTP requests for each database operation. For example, this guide uses the cURL commands to test each operation of employeeService as follows. 

**Add new employee** 
```
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"
```

Output:  
```
< HTTP/1.1 200 OK
{"Status":"Data Inserted Successfully"}
```

**Retrieve employee data** 
```
curl -v  "http://localhost:9090/records/employee/1"
```

Output: 
```
< HTTP/1.1 200 OK
[{"EmployeeID":1,"Name":"Alice","Age":20,"SSN":123456789}]
```
**Update an existing employee data** 
```
curl -v -X PUT -d '{"name":"Alice Updated", "age":30,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"
```

Output: 
```
< HTTP/1.1 200 OK
{"Status":"Data Updated Successfully"}
```

**Delete employee data** 
```
curl -v -X DELETE "http://localhost:9090/records/employee/1"
```

Output:
```
< HTTP/1.1 200 OK
{"Status":"Data Deleted Successfully"}
```

### <a name="unit-testing"></a> Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a file named as `test`. The naming convention should be as follows.
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g., testAddEmployeeResource()

This guide contains unit test cases in the respective folders. The two test cases are written to test the Employee Data Service and the Database utilities package.

To run the unit tests, go to the sample root directory and run the following command.
```bash
$ ballerina test data_backed_service
```


## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that are listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You can use the Ballerina executable archive (.balx) file that you created above and run it in your local environment as follows. 

```
ballerina run employee_db_service.balx 
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
