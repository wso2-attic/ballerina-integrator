# Database Interaction

Data inside a database can be exposed to the outside world by using a database backed RESTful web service. RESTful API calls enable you to add, view, update, and remove data stored in a database from the outside world.

> This guide walks you through building a database-backed RESTful web service with Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you'll build

You'll build an employee data management REST service that performs CRUD Operations (Create, Read, Update, Delete) on the MySQL database. Also, this guide walks you through the process of accessing relational data via the Ballerina language. The service will have following functionalities.

* Add new employees to the database via HTTP POST method
* Retrieve an existing employee details from the database via HTTP GET method
* Update an existing employee in the database via HTTP PUT method
* Delete an existing employee from the database via HTTP DELETE method

Basically, this service will deal with a MySQL database and expose the data operations as a web service. Refer to the following diagram to understand the complete end-to-end scenario.


![alt text](/resources/data-backed-service.svg)


## Prerequisites
 
* [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
* A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
* [MySQL version 5.6 or later](https://www.mysql.com/downloads/)
* [Official JDBC driver](https://dev.mysql.com/downloads/connector/j/) for MySQL
  * Copy the downloaded JDBC driver to the `<BALLERINA_HOME>/bre/lib` folder.   
  
    > **E.g.**   
    > _On Linux:_ `mysql-connector-java-8.x.x.jar -> /usr/lib/ballerina/ballerina-x.xx.x/bre/lib/`
    > _On Mac:_ `mysql-connector-java-8.x.x.jar -> ~/Library/Ballerina/ballerina-x.xx.x/bre/lib/`
    > _On Windows:_ `mysql-connector-java-8.x.x.jar -> C:\Program Files\Ballerina\ballerina-x.xx.x\bre\lib\`

### Optional requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to "Testing" section by skipping "Developing" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any module structure, use the following module structure for this project to follow this guide.
```
data-backed-service
 └── guide
      └── data_backed_service
      |    ├── employee_db_service.bal
      |    └── test
      |        └── employee_db_service_test.bal
      └── ballerina.conf
```

- Create the above directories in your local machine and also create empty `.bal` and `.conf` files.

- Then open the terminal and navigate to `data-backed-service/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the SQL data backed web service
Ballerina language has built-in support for writing web services. The `service` keyword in Ballerina simply defines a web service. Inside the service block, we can have all the required resources. You can define a resource function inside the service. You can implement the business logic inside a resource function using Ballerina language syntax.
We can use the following database schema to store employee data.
```
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| EmployeeID | int(11)     | NO   | PRI | NULL    |       |
| Name       | varchar(50) | YES  |     | NULL    |       |
| Age        | int(11)     | YES  |     | NULL    |       |
| SSN        | int(11)     | YES  |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+

```
The following Ballerina code is the employee data service with resource functions to add, retrieve, update and delete employee data.

##### employee_db_service.bal

```ballerina
import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import ballerina/sql;

listener http:Listener httpListener = new(9090);

type Employee record {
    string name;
    int age;
    int ssn;
    int employeeId;
};

// Create SQL client for MySQL database
mysql:Client employeeDB = new({
        host: config:getAsString("DATABASE_HOST", defaultValue = "localhost"),
        port: config:getAsInt("DATABASE_PORT", defaultValue = 3306),
        name: config:getAsString("DATABASE_NAME", defaultValue = "EMPLOYEE_RECORDS"),
        username: config:getAsString("DATABASE_USERNAME", defaultValue = "root"),
        password: config:getAsString("DATABASE_PASSWORD", defaultValue = "root"),
        dbOptions: { useSSL: false }
    });

// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service EmployeeData on httpListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/employee/"
    }
    resource function addEmployeeResource(http:Caller httpCaller, http:Request request) {
        // Initialize an empty http response message
        http:Response response = new;

        // Extract the data from the request payload
        var payloadJson = request.getJsonPayload();

        if (payloadJson is json) {
            Employee|error employeeData = Employee.convert(payloadJson);

            if (employeeData is Employee) {
                // Validate JSON payload
                if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
                    employeeData.employeeId == 0) {
                    response.setPayload("Error : json payload should contain
                    {name:<string>, age:<int>, ssn:<123456>, employeeId:<int>}");
                    response.statusCode = 400;
                } else {
                    // Invoke insertData function to save data in the MySQL database
                    json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn,
                        employeeData.employeeId);
                    // Send the response back to the client with the employee data
                    response.setPayload(ret);
                }
            } else {
                // Send an error response in case of a conversion failure
                response.statusCode = 400;
                response.setPayload("Error: Please send the JSON payload in the correct format");
            }
        } else {
            // Send an error response in case of an error in retriving the request payload
            response.statusCode = 500;
            response.setPayload("Error: An internal error occurred");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employee/{employeeId}"
    }
    resource function retrieveEmployeeResource(http:Caller httpCaller, http:Request request, string
        employeeId) {
        // Initialize an empty http response message
        http:Response response = new;
        // Convert the employeeId string to integer
        var empID = int.convert(employeeId);
        if (empID is int) {
            // Invoke retrieveById function to retrieve data from Mymysql database
            var employeeData = retrieveById(empID);
            // Send the response back to the client with the employee data
            response.setPayload(untaint employeeData);
        } else {
            response.statusCode = 400;
            response.setPayload("Error: employeeId parameter should be a valid integer");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/employee/"
    }
    resource function updateEmployeeResource(http:Caller httpCaller, http:Request request) {
        // Initialize an empty http response message
        http:Response response = new;

        // Extract the data from the request payload
        var payloadJson = request.getJsonPayload();
        if (payloadJson is json) {
            Employee|error employeeData = Employee.convert(payloadJson);

            if (employeeData is Employee) {
                if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
                    employeeData.employeeId == 0) {
                    response.setPayload("Error : json payload should contain
                        {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
                    response.statusCode = 400;
                } else {
                    // Invoke updateData function to update data in mysql database
                    json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn,
                        employeeData.employeeId);
                    // Send the response back to the client with the employee data
                    response.setPayload(ret);
                }
            } else {
                // Send an error response in case of a conversion failure
                response.statusCode = 400;
                response.setPayload("Error: Please send the JSON payload in the correct format");
            }
        } else {
            // Send an error response in case of an error in retriving the request payload
            response.statusCode = 500;
            response.setPayload("Error: An internal error occurred");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/employee/{employeeId}"
    }
    resource function deleteEmployeeResource(http:Caller httpCaller, http:Request request, string
        employeeId) {
        // Initialize an empty http response message
        http:Response response = new;
        // Convert the employeeId string to integer
        var empID = int.convert(employeeId);
        if (empID is int) {
            var deleteStatus = deleteData(empID);
            // Send the response back to the client with the employee data
            response.setPayload(deleteStatus);
        } else {
            response.statusCode = 400;
            response.setPayload("Error: employeeId parameter should be a valid integer");
        }
        var respondRet = httpCaller->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
    }
}

public function insertData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus;
    string sqlString =
    "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    // Check type to verify the validity of the result from database
    if (ret is sql:UpdateResult) {
        updateStatus = { "Status": "Data Inserted Successfully" };
    } else {
        updateStatus = { "Status": "Data Not Inserted", "Error": "Error occurred in data update" };
        // Log the error for the service maintainers.
        log:printError("Error occurred in data update", err = ret);
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {
    json jsonReturnValue = {};
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select remote function defined in ballerina sql client
    var ret = employeeDB->select(sqlString, (), employeeID);
    if (ret is table<record {}>) {
        // Convert the sql data table into JSON using type conversion
        var jsonConvertRet = json.convert(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    } else {
        jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data retrieval" };
        log:printError("Error occurred in data retrieval", err = ret);
    }
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, int employeeId) returns (json) {
    json updateStatus;
    string sqlString =
    "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update remote function defined in ballerina sql client
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    if (ret is sql:UpdateResult) {
        if (ret.updatedRowCount > 0) {
            updateStatus = { "Status": "Data Updated Successfully" };
        } else {
            updateStatus = { "Status": "Data Not Updated" };
        }
    } else {
        updateStatus = { "Status": "Data Not Updated",  "Error": "Error occurred during update operation" };
        // Log the error for the service maintainers.
        log:printError("Error occurred during update operation", err = ret);
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    json updateStatus;

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update remote function defined in ballerina sql client
    var ret = employeeDB->update(sqlString, employeeID);
    if (ret is sql:UpdateResult) {
        updateStatus = { "Status": "Data Deleted Successfully" };
    } else {
        updateStatus = { "Status": "Data Not Deleted",  "Error": "Error occurred during delete operation" };
        // Log the error for the service maintainers.
        log:printError("Error occurred during delete operation", err = ret);
    }
    return updateStatus;
}

```

A remote function in Ballerina indicates that it communicates with some remote service through the network. In this case, the remote service is a MySQL database. `employeeDB` is the reference name for the MySQL client object which encapsulates aforementioned set of remote functions. The rest of the code is for preparing SQL queries and executing them by calling these remote functions of the Ballerina MySQL client.

You can implement custom functions in Ballerina that perform specific tasks. For this scenario, we have included the following functions to interact with the MySQL database.

- insertData
- retrieveById
- updateData
- deleteData

## Testing 

### Before you begin
* Download & run the SQL script [initializeDataBase.sql](resources/initializeDataBase.sql), to initialize the database and to create the required table.
```
   $mysql -u username -p <initializeDataBase.sql 
``` 

- Add database configurations to the `ballerina.conf` file
   - `ballerina.conf` file can be used to provide external configurations to the Ballerina programs. Since this guide needs MySQL database integration, a Ballerina coniguration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
```
   DATABASE_HOST = "localhost"
   DATABASE_PORT = 3306
   DATABASE_USERNAME = "username"
   DATABASE_PASSWORD = "password"
   DATABASE_NAME = "EMPLOYEE_RECORDS"
```

### Invoking the employee database service 

- To run the developed employee database service you need to navigate to `data-backed-service/guide` and execute the following command
```
$ ballerina run data_backed_service
```

- You can test the functionality of the employee database management RESTFul service by sending HTTP requests for each database operation. For example, this guide uses the cURL commands to test each operation of employeeService as follows. 

**Add new employee** 
```
curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output:  
{"Status":"Data Inserted Successfully"}
```

**Retrieve employee data** 
```
curl -v  "http://localhost:9090/records/employee/1"

Output: 
[{"EmployeeID":1,"Name":"Alice","Age":20,"SSN":123456789}]
```
**Update an existing employee data** 
```
curl -v -X PUT -d '{"name":"Alice Updated", "age":30,"ssn":123456789,"employeeId":1}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output: 
{"Status":"Data Updated Successfully"}
```

**Delete employee data** 
```
curl -v -X DELETE "http://localhost:9090/records/employee/1"

Output: 
{"Status":"Data Deleted Successfully"}
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same module inside a folder named as `test`.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testAddEmployeeResource() {
   ...
```
You can download the [employee_db_service_test.bal](guide/data_backed_service/tests/employee_db_service_test.bal) sample, which contains unit test cases to test the resources available in the employee_data_service we implemented above.

To run the unit tests, go to the `guide` directory and run the following command.
Please note that `--config` option is required if it is needed to read configurations from a ballerina configuration file.

```bash
$ ballerina test --config ballerina.conf
```

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that are listed below. 

### Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You need to have the Ballerina installed on your local machine. To deploy simply execute all the following steps.  

- As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory structure of the service that we developed above and it will create an executable binary out of that. 

```
   $ ballerina build data_backed_service
```

- Once the data_backed_service.balx is created in the ./target folder, you can run that with the following command.

```
   $ ballerina run target/data_backed_service.balx
```

- The successful execution of the service should show us the following output. 

```
   ballerina: initiating service(s) in 'data_backed_service'
   ballerina: started HTTP/WS server endpoint 0.0.0.0:9090
```
### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. Since this guide requires MySQL as a prerequisite, you need a couple of more steps to configure MySQL in docker container.   

First let's see how to configure MySQL in docker container.

  * Initially, you need to pull the MySQL docker image using the below command.
```
    $ docker pull mysql:5.7.22
```

  * Then run the MySQL as root user with container name `docker_mysql` and password being `root` to easily follow this guide. 
```
    $ docker run --name docker_mysql -e MYSQL_ROOT_PASSWORD=root -d mysql:5.7.22
```

  * Check whether the MySQL container is up and running using the following command.
```
    $ docker ps
```

  * Navigate to the sample root directory and run the below command to copy the database script file to the MySQL Docker container, which will be used to create the required database.
```
    $ docker cp ./resources/initializeDataBase.sql <CONTAINER_ID>:/
```

  * Run the SQL script file in the container to create the required database using the below command.
```
    $ docker exec <CONTAINER_ID> /bin/sh -c 'mysql -u root -proot </initializeDataBase.sql'
```

Now let's add the required docker annotations in our employee_db_service. You need to import  `` ballerinax/docker; `` and add the docker annotations as shown below to enable docker image generation during the build time. 

##### employee_db_service.bal
```ballerina
// Other imports
import ballerinax/docker;

// Employee type definition

// Create SQL endpoint to MySQL database
mysql:Client employeeDB = new({
        host: <MySQL_Container_IP>,
        port: 3306,
        name: "EMPLOYEE_RECORDS",
        username: "root",
        password: "root",
        poolOptions: { maximumPoolSize: 5 }
    });

@docker:Config {
    registry: "ballerina.guides.io",
    name: "employee_database_service",
    tag: "v1.0",
    baseImage: "ballerina/ballerina:<BALLERINA_VERSION>"
}

@docker:CopyFiles {
    files: [{ source: <path_to_JDBC_jar>,
            target: "/ballerina/runtime/bre/lib" }]
}

@docker:Expose {}

listener http:Listener httpListener = new(9090);

@http:ServiceConfig {
    basePath: "/records"
}
service EmployeeData on httpListener {
``` 

 - `@docker:Config` annotation is used to provide the basic docker image configurations for the sample. `@docker:CopyFiles` is used to copy the MySQL jar file into the ballerina bre/lib folder. Make sure to replace the `<path_to_JDBC_jar>` with your JDBC jar's path. `@docker:Expose {}` is used to expose the port. Finally you need to change the host field in the  `mysql:Client` endpoint definition to the IP address of the MySQL container. You can obtain this IP address using the below command.

```
   $ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <Container_ID>
```

 - Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/guide/` folder and run the following command.
  
```
   $ ballerina build data_backed_service

   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/employee_database_service:v1.0
```

- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```   
   $ docker run -d -p 9090:9090 ballerina.guides.io/employee_database_service:v1.0
```

- Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 

- You can access the service using the same curl commands that we've used above. 
 
```
   curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
   "http://localhost:9090/records/employee" -H "Content-Type:application/json"
```

### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create docker images prior to deploying it on Kubernetes. Refer to [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

Since this guide requires MySQL as a prerequisite, you need a couple of more steps to create a MySQL pod and use it with our sample.  

First let's look at how we can create a MySQL pod in kubernetes. If you are working with minikube, it will be convenient to use the minikube's in-built docker daemon and push the mysql docker image we are about to build to the minikube's docker registry. This is because during the next steps, in the case of minikube, the docker image we build for employee_database_service will also be pushed to minikube's docker registry. Having both images in the same registry, will reduce the configuration steps.
Run the following command to start using minikube's in-built docker daemon.

```bash
minikube docker-env
```
    
   * Navigate to the <sample_root>/resources directory and run the below command.
```
     $ docker build -t mysql-ballerina:1.0  .
```

   *  Then run the following command from the same directory to create the MySQL pod by creating a deployment and service for MySQL. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` folder.
```
      $ kubectl create -f ./kubernetes/
```

Now we need to import `` ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### employee_db_service.bal

```ballerina
// Other imports
import ballerinax/kubernetes;

// Employee type definition

// Create SQL endpoint to MySQL database
mysql:Client employeeDB = new({
        host: "mysql-service",
        port: 3306,
        name: "EMPLOYEE_RECORDS",
        username: "root",
        password: "root",
        poolOptions: { maximumPoolSize: 5 }
    });

@kubernetes:Ingress {
    hostname: "ballerina.guides.io",
    name: "ballerina-guides-employee-database-service",
    path: "/"
}

@kubernetes:Service {
    serviceType: "NodePort",
    name: "ballerina-guides-employee-database-service"
}

@kubernetes:Deployment {
    image: "ballerina.guides.io/employee_database_service:v1.0",
    name: "ballerina-guides-employee-database-service",
    baseImage: "ballerina/ballerina:<BALLERINA_VERSION>",
    copyFiles: [{ target: "/ballerina/runtime/bre/lib",
                source: <path_to_JDBC_jar> }]
}

listener http:Listener httpListener = new(9090);

@http:ServiceConfig {
    basePath: "/records"
}
service EmployeeData on httpListener {
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. `copyFiles` field is used to copy the MySQL jar file into the ballerina bre/lib folder. Make sure to replace the `<path_to_JDBC_jar>` with your JDBC jar's path.
- Please note that if you are using Minikube it is required to add the `` dockerHost `` and `` dockerCertPath `` configurations under ``  @kubernetes:Deployment ``.
eg:
``` ballerina
@kubernetes:Deployment {
    image: "ballerina.guides.io/employee_database_service:v1.0",
    name: "ballerina-guides-employee-database-service",
    baseImage: "ballerina/ballerina:<BALLERINA_VERSION>",
    copyFiles: [{ target: "/ballerina/runtime/bre/lib",
                source: <path_to_JDBC_jar> }],
    dockerHost: "tcp://<MINIKUBE_IP>:<DOCKER_PORT>",
    dockerCertPath: "<MINIKUBE_CERT_PATH>"
}
```

- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build data_backed_service

   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/kubernetes/data_backed_service
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/kubernetes/data_backed_service``.
- Now you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/kubernetes/data_backed_service

   deployment.extensions "ballerina-guides-employee-database-service" created
   ingress.extensions "ballerina-guides-employee-database-service" created
   service "ballerina-guides-employee-database-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

```
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
   curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
   "http://localhost:<Node_Port>/records/employee" -H "Content-Type:application/json"  
```

If you are using Minikube the request would be as follows.

```
   curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
   "http://<Minikube_IP>:<Node_Port>/records/employee" -H "Content-Type:application/json"
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

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc. Refer to [how-to-observe-ballerina-code](https://ballerina.io/learn/how-to-observe-ballerina-code/) for more information.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file and starting the ballerina service using it.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```
NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations default values are load as the other configuration parameters of metrics and tracing.

### Tracing 

You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.

- You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described above.
```
   [b7a.observability]

   [b7a.observability.tracing]
   enabled=true
   name="jaeger"

   [b7a.observability.tracing.jaeger]
   reporter.hostname="localhost"
   reporter.port=5775
   sampler.param=1.0
   sampler.type="const"
   reporter.flush.interval.ms=2000
   reporter.log.spans=true
   reporter.max.buffer.spans=1000
```

- Run Jaeger docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `data-backed-service/guide` and run the data-backed-service using the following command
```
   $ ballerina run data_backed_service
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alarts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for Ballerina database service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
```

- Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
- Run the Prometheus docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `data-backed-service/guide` and run the data-backed-service using the following command
```
   $ ballerina run data_backed_service
```

- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log module for logging to the console. You can import ballerina/log module and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `data-backed-service/guide`
```
   $ nohup ballerina run data_backed_service/ &>> ballerina.log&
```
   NOTE: This will write the console log to the `ballerina.log` file in the `data-backed-service/guide` directory

- Start Elasticsearch using the following command

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.5.1
```

- Configure logstash to format the ballerina logs

i) Create a file named `logstash.conf` with the following content
```
input {  
 beats{ 
     port => 5044 
 }  
}

filter {  
 grok{  
     match => { 
	 "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	 \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }  
 }  
}   

output {  
 elasticsearch{  
     hosts => "elasticsearch:9200"  
     index => "store"  
     document_type => "store_logs"  
 }  
}  
```

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
```
  
 - Configure filebeat to ship the ballerina logs
    
i) Create a file named `filebeat.yml` with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of filebeat.yml file using `$chmod go-w filebeat.yml` 

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -v {SAMPLE_ROOT}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/data_backed_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```

