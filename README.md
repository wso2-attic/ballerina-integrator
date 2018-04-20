# Database Interaction

Data inside a database can be exposed to the outside world by using a database backed RESTful web service. RESTful API calls enable you to add, view, update, and remove data stored in a database from the outside world.

> This guide walks you through building a database-backed RESTful web service with Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Before you begin](#before-you-begin)
- [Developing the SQL data backed web service](#developing-the-sql-data-backed-web-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you'll build

You'll build an employee data management REST service that performs CRUD Operations (Create, Read, Update, Delete) on the MySQL database. Also, this guide walks you through the process of accessing relational data via the Ballerina language. The service will have following functionalities.

* Add new employees to the database via HTTP POST method
* Retrieve an existing employee details from the database via HTTP GET method
* Update an existing employee in the database via HTTP PUT method
* Delete an existing employee from the database via HTTP DELETE method

Basically, this service will deal with a MySQL database and expose the data operations as a web service. Refer to the following diagram to understand the complete end-to-end scenario.


![alt text](/images/data-backed-service.svg)


## Prerequisites
 
* JDK 1.8 or later
* [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
* MySQL version 5.6 or better
* Official JDBC driver for MySQL ( Download https://dev.mysql.com/downloads/connector/j/)
  * Copy the downloaded JDBC driver to the <BALLERINA_HOME>/bre/lib folder 
* A Text Editor or an IDE

**Optional requirements**
- [Docker](https://docs.docker.com/engine/installation/)
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))


## Before you begin
* Run the SQL script `initializeDataBase.sql` provided in the resources folder, to initialize the database and the required table by entering the below command from the project root directory.
```
  $ mysql -u username -p <./resources/initializeDataBase.sql 
``` 

* Add database configurations to the `ballerina.conf` file
   * `ballerina.conf` file can be used to provide external configurations to the Ballerina programs. Since this guide needs MySQL database integration, a Ballerina coniguration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
```
      DATABASE_HOST = localhost
      DATABASE_PORT = 3306
      DATABASE_USERNAME = username
      DATABASE_PASSWORD = password
      DATABASE_NAME = EMPLOYEE_RECORDS
```


## Developing the SQL data backed web service

> If you want to skip the basics, you can download the git repo and directly move to "Testing" section by skipping "Developing" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.
```
data-backed-service
  ├── resources
  │   └── initializeDataBase.sql
  └── src
      ├── ballerina.conf
      ├── Ballerina.toml
      └── data_backed_service
          ├── employee_db_service.bal
          └── test
              └── employee_db_service_test.bal
```

You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `data-backed-service` and navigate to that directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
$ ballerina init -i

Create Ballerina.toml [yes/y, no/n]: (y) y
Organization name: (username) data-backed-service
Version: (0.0.1) 
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) guide.data_backed_service
Ballerina source [service/s, main/m, finish/f]: (f) f

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change the names of the generated files to match with our guide project filenames.

#### Initialize the Ballerina project

Once you created your package structure, go to the sample src directory and run the following command to initialize your Ballerina project.

```bash
  $ballerina init
```

The above command will initialize the project with a `Ballerina.toml` file and `.ballerina` implementation directory that contain a list of packages in the current directory.

### Implementation of the Ballerina web service
Ballerina language has built-in support for writing web services. The `service` keyword in Ballerina simply defines a web service. Inside the service block, we can have all the required resources. You can define a resource inside the service. You can implement the business logic inside a resource using Ballerina language syntaxes. The following Ballerina code is the employee data service with resources to add, retrieve, update and delete employee data.

```ballerina
package data_backed_service;

import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/mime;
import ballerina/http;
import ballerina/config;
import ballerina/io;
//import ballerinax/docker;

type Employee {
    string name;
    int age;
    int ssn;
    int employeeId;
};

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host:"localhost",
    port:3306,
    name:"EMPLOYEE_RECORDS",
    username:"root",
    password:"qwe123",
    poolOptions:{maximumPoolSize:5}
};

endpoint http:Listener listener {
    port:9090
};

//@docker:Config {
//    name:"employee-database-service",
//    tag:"v1.0"
//}

@http:ServiceConfig {
    basePath:"/records"
}
service<http:Service> employee_data_service bind listener {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/employee/"
    }
    addEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        // Extract the data from the request payload
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData = check <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0
            || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            //return;
        }

        // Invoke insertData function to save data in the Mymysql database
        json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn,
            employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/employee/{employeeId}"
    }
    retrieveEmployeeResource(endpoint httpConnection, http:Request request,
    string employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
                // Invoke retrieveById function to retrieve data from Mymysql database
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
    updateEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        var requestPayload = request.getJsonPayload();

        match requestPayload {
            json payloadJson => {
                employeeData = check <Employee>payloadJson;
            }
            mime:EntityError err => {
                log:printError(err.message);
            }
        }
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0
            || employeeData.employeeId == 0) {
            response.setStringPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection -> respond(response);
            //return;
        }

        // Invoke updateData function to update data in Mymysql database
        json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn,
            employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection -> respond(response);
    }

    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/employee/{employeeId}"
    }
    deleteEmployeeResource(endpoint httpConnection, http:Request request,
    string employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var castVal = <int>employeeId;
        match castVal {
            int empID => {
                // Invoke deleteData function to delete the data from Mymysql database
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

public function insertData(string name, int age, int ssn, int employeeId) returns (json) {

    json updateStatus;
    // Prepare the mysql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_VARCHAR, name, sql:DIRECTION_IN);
    sql:Parameter para2 = (sql:TYPE_INTEGER, age, sql:DIRECTION_IN);
    sql:Parameter para3 = (sql:TYPE_INTEGER, ssn, sql:DIRECTION_IN);
    sql:Parameter para4 = (sql:TYPE_INTEGER, employeeId, sql:DIRECTION_IN);
    string sqlStr = "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action in ballerina sql connector
    var ret = employeeDB -> update(sqlStr, para1, para2, para3, para4);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Inserted Successfully"};
        }
        error err => {
            updateStatus = {"Status":"Data Not Inserted", "Error":err.message};
        }
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_INTEGER, employeeID, sql:DIRECTION_IN);
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select action defined in ballerina sql connector
    table dataTable = check employeeDB -> select(sqlString, null, para1);
    // Convert the sql data table into JSON using type conversion
    var jsonReturnValue = check <json>dataTable;
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, int employeeId) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_VARCHAR, name, sql:DIRECTION_IN);
    sql:Parameter para2 = (sql:TYPE_INTEGER, age, sql:DIRECTION_IN);
    sql:Parameter para3 = (sql:TYPE_INTEGER, ssn, sql:DIRECTION_IN);
    sql:Parameter para4 = (sql:TYPE_INTEGER, employeeId, sql:DIRECTION_IN);
    string sqlStr = "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID =?";
    // Update existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlStr, para1, para2, para3, para4);
    match ret {
        int updateRowCount => {
            if (updateRowCount > 0) {
                updateStatus = {"Status":"Data Updated Successfully"};
            }
            else {
                updateStatus = {"Status":"Data Not Updated"};
            }
        }
        error err => {
            updateStatus = {"Status":"Data Not Updated", "Error":err.message};
        }
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    // Initialize update status as unsuccessful MySQL operation
    json updateStatus = {};

    // Prepare the sql string with employee data as parameters
    sql:Parameter para1 = (sql:TYPE_INTEGER, employeeID, sql:DIRECTION_IN);
    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql connector
    var ret = employeeDB -> update(sqlString, para1);
    match ret {
        int updateRowCount => {
            updateStatus = {"Status":"Data Deleted Successfully"};
        }
        error err => {
            updateStatus = {"Status":"Data Not Deleted", "Error":err.message};
        }
    }
    return updateStatus;
}
```

Please refer to the `src/data_backed_service/employee_db_service.bal` file for the complete implementaion of the employee management web service.


You can implement custom functions in Ballerina that do specific tasks. For this scenario, you need to have functions to deal with the MySQL database.

The `endpoint` keyword in Ballerina refers to a connection with a remote service. In this case, the remote service is a MySQL database. `employeeDB` is the reference name for the SQL endpoint. The endpoint is initialized with an SQL connection. The rest of the code is just preparing SQL queries and executing them by calling the `update` action in the `ballerina/mysql` package. Finally, the status of the SQL operation is returned as a JSON file.

## Testing 

### Invoking the RESTful service 

You can run the RESTful service that you developed above, in your local environment. You need to have the Ballerina installation on your local machine and simply point to the <ballerina>/bin/ballerina binary to execute all the following steps.  

- As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory structure of the service that we developed above and it will create an executable binary out of that. 

```
$ ballerina build data_backed_service
```

- Once the data_backed_service.balx is created, you can run that with the following command. 

```
$ ballerina run data_backed_service.balx 
```

- The successful execution of the service should show us the following output. 

```
ballerina: deploying service(s) in 'data_backed_service'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
```

- You can test the functionality of the employee database management RESTFul service by sending HTTP requests for each database operation. For example, this guide uses the cURL commands to test each operation of employeeService as follows. 

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

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a file named as `test`. The naming convention should be as follows.
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g., testAddEmployeeResource()

This guide contains unit test cases in the respective folders. The two test cases are written to test the Employee Data Service and the Database utilities package.

To run the unit tests, go to the sample root directory and run the following command.
```bash
$ ballerina test data_backed_service
```


## Deployment

Once you are done with the development, you can deploy the service using any of the methods that are listed below. 

### Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You can use the Ballerina executable archive (.balx) file that you created above and run it in your local environment as follows. 

```
ballerina run employee_db_service.balx 
```

### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. Since this guide requires MySQL as a prerequisite, you need a couple of more steps to configure MySQL in docker container.   

- First let's see how to configure MySQL in docker container.

  * Initially, you need to pull the MySQL docker image using the below command.
```
    $docker pull mysql
```

  * Then run the MySQL as root user with container name `docker_mysql` and password being `root` to easily follow this guide. 
```
    $docker run --name docker_mysql -e MYSQL_ROOT_PASSWORD=root -d mysql:latest
```

  * Check whether the MySQL container is up and running using the following command.
```
    $docker ps
```

  * Navigate to the sample root directory and run the below command to copy the database script file to the MySQL Docker container, which will be used to create the required database.
```
    $docker cp ./resources/initializeDataBase.sql <CONTAINER_ID>:/
```

  * Run the SQL script file in the container to create the required database using the below command.
```
    $docker exec <CONTAINER_ID> /bin/sh -c 'mysql -u root -proot </initializeDataBase.sql'    
```

- Now let's add the required docker annotations in our employee_db_service. You need to import  `` ballerinax/docker; `` and add the docker annotations as shown below to enable docker image generation during the build time. 

##### employee_db_service.bal
```ballerina
package data_backed_service;

// Other imports
import ballerinax/docker;

// Employee type definition

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host:<MySQL_Container_IP>,
    port:3306,
    name:"EMPLOYEE_RECORDS",
    username:"root",
    password:"root",
    poolOptions:{maximumPoolSize:5}
};

@docker:Config {
    registry:"ballerina.guides.io",
    name:"employee_database_service",
    tag:"v1.0"
}

@docker:CopyFiles {
    files:[{source:<path_to_JDBC_jar>,
            target:"/ballerina/runtime/bre/lib"}]
}

@docker:Expose {}

endpoint http:Listener listener {
    port:9090
};

@http:ServiceConfig {
    basePath:"/records"
}
service<http:Service> employee_data_service bind listener {
``` 

`@docker:Config` annotation is used to provide the basic docker image configurations for the sample. `@docker:CopyFiles` is used to copy the MySQL jar file into the ballerina bre/lib folder. Make sure to replace the `<path_to_JDBC_jar>` with your JDBC jar's path. `@docker:Expose {}` is used to expose the port. Finally you need to change the host field in the  `mysql:Client` endpoint definition to the IP address of the MySQL container. You can obtain this IP address using the below command.

```
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <Container_ID>
```

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command.  
  
```
$ballerina build data_backed_service

Run following command to start docker container: 
docker run -d -p 9090:9090 ballerina.guides.io/employee_database_service:v1.0
```

- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```   
docker run -d -p 9090:9090 ballerina.guides.io/employee_database_service:v1.0
```

  Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 

- You can access the service using the same curl commands that we've used above. 
 
```
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"
```

NOTE: Refer to the [Ballerina_Docker_Extension](https://github.com/ballerinax/docker) GitHub page for more details and samples on Docker deployment with Ballerina.

### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes with the use of annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create docker images prior to deploying it on Kubernetes. 

Since this guide requires MySQL as a prerequisite, you need a couple of more steps to create a MySQL pod and use it with our sample.  

- First let's look at how we can create a MySQL pod in kubernetes.
    
   * Navigate to the <sample_root>/resources directory and run the below command.
```
     docker build -t mysql-ballerina:1.0  .
```

   *  Then run the following command from the same directory to create the MySQL pod by creating a deployment and service for MySQL. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` folder.
```
      kubectl create -f ./kubernetes/
```

- Now we need to import `` ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### employee_db_service.bal

```ballerina
package data_backed_service;

// Other imports
import ballerinax/kubernetes;

// Employee type definition

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host:"mysql-service",
    port:3306,
    name:"EMPLOYEE_RECORDS",
    username:"root",
    password:"root",
    poolOptions:{maximumPoolSize:5}
};

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-employee-database-service",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-employee-database-service"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/employee_database_service:v1.0",
    name:"ballerina-guides-employee-database-service",
    copyFiles:[{target:"/ballerina/runtime/bre/lib",
                source:<path_to_JDBC_jar>}]
}

endpoint http:Listener listener {
    port:9090
};

@http:ServiceConfig {
    basePath:"/records"
}
service<http:Service> employee_data_service bind listener {      
``` 
- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. CopyFiles field is used to copy the MySQL jar file into the ballerina bre/lib folder. Make sure to replace the `<path_to_JDBC_jar>` with your JDBC jar's path.

- We have also specified `` @kubernetes:Service {} `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
$ballerina build data_backed_service

Run following command to deploy kubernetes artifacts:  
kubectl apply -f ./target/data_backed_service/kubernetes
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/data_backed_service/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
$kubectl apply -f ./target/data_backed_service/kubernetes 

deployment.extensions "ballerina-guides-employee-database-service" created
ingress.extensions "ballerina-guides-employee-database-service" created
service "ballerina-guides-employee-database-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

```
$kubectl get service
$kubectl get deploy
$kubectl get pods
$kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:<Node_Port>/records/employee" -H "Content-Type:application/json"  
```

Ingress:

Add `/etc/hosts` entry to match hostname. 

``` 
127.0.0.1 ballerina.guides.io
```

Access the service 

``` 
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://ballerina.guides.io/records/employee" -H "Content-Type:application/json" 
```

NOTE: Refer to the [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) GitHub page for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 
