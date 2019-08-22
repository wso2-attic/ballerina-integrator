# Sending a Simple Message to a Datasource

In this tutorial, let’s try a simple scenario where a user can execute operations related to doctors in a Health Care System. Information about doctors is stored in a MySql database. We will configure a RESTful service using Ballerina to receive the client request, and to expose the information in the database, thereby decoupling the client and the back-end database.

#### What you will build

The RESTful service we are going to create contains resources to carry out the following actions.

- Insert details about doctors
- Update doctor information
- Delete records of a particular doctor
- Retrieve a list of doctors given the doctor's speciality (category)

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS. From this point on, we refer to this installed directory as <BALLERINA_HOME>.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- Download and install MySQL <!--version-->
- Download the JDBC Driver .jar file and copy it into the <BALLERINA_HOME>/bre/lib folder.
- Download and run the **Doctors.sql** script file from [here](https://github.com/wso2/ballerina-integrator/raw/master/examples/integration-tutorials/sending-a-simple-message-to-a-datasource/sql-data-service/resources/Doctors.sql) to create the backend database.

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Creating the Project Structure](#creating-the-project-structure)
  - [Creating the Client to access the Backend Database](#creating-the-client-to-access-the-backend-database)
  - [Creating the RESTful service to perform database transactions](#creating-the-restful-service-to-perform-database-transactions)
  - [Creating the resources for accessing the database](#creating-the-resources-for-accessing-the-database)
- [Deployment](#deployment)
  - [Deploying Locally](#deploying-locally)
  - [Deploying on Docker](#deploying-on-docker)
- [Testing](#testing)
  - [Starting the Database Service](#starting-the-database-service)
  - [Invoking the Database Service](#invoking-the-database-service)

### Implementation

#### Creating the Project Structure

Ballerina is a complete programming language that supports custom project structures. We will use the following package structure for this guide.

```
  └──sending-a-simple-message-to-a-datasource
    └── guide
        ├── ballerina.conf
        └── db_interaction
             ├── data_service.bal
             ├── sql_utilities.bal
             ├── sql_queries.bal
             └── sql_service_constants.bal
```

Create the above directories in your local machine and create the empty .bal files as mentioned.

Then open the terminal and navigate to `sending-a-simple-message-to-a-datasource/guide` directory. Run the following command to initialize a Ballerina project.

```
$ ballerina new MyNewProject
```

#### Creating the Client to Access the Backend Database

First we have to define the MySQL client in the `data_service.bal` file.

The properties of the database connection should be added to a configuration file, and accessed from the file at runtime. In Ballerina, name of this config file has to be `ballerina.conf`.

Navigate to `sending-a-simple-message-to-a-datasource/guide` directory, create the config file `ballerina.conf`, and add the following database connection properties to the file.

```
MYSQL_DB_HOST = "localhost"
MYSQL_DB_PORT = "3306"
MYSQL_DB_NAME = "Hospital"
MYSQL_DB_USERNAME = "sqlUsername"
MYSQL_DB_PASSWORD = "sqlPassword"
```

In the `data_service.bal` file, create the MySQL client as below.

```ballerina
mysql:Client testDB = new({
        host: config:getAsString("MYSQL_DB_HOST"),
        port: config:getAsInt("MYSQL_DB_PORT"),
        name: config:getAsString("MYSQL_DB_NAME"),
        username: config:getAsString("MYSQL_DB_USERNAME"),
        password: config:getAsString("MYSQL_DB_PASSWORD"),
        dbOptions: { useSSL: false }
});
```

#### Creating the RESTful service to perform database transactions

Let's get started with implementing the services which perform database transactions.

In the `data_service.bal` file, create a listener to listen to API requests on port 9092 as below.

```ballerina
listener http:Listener httpListener = new(9092);
```

Add the base path of the service.

```ballerina
@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}
service dbTransactionService on httpListener {
    // Implementation of resources
}
```

#### Creating the resources for accessing the database

Now, let's define the resources required to access the database in the service we created above, in the `data_service.bal` file.

```ballerina
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/doctor/{name}"
    }
    resource function doctorData(http:Caller caller, http:Request req, string name) {
        // implementation
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/doctor"
    }
    resource function addDoctorData(http:Caller caller, http:Request request, string fname) {
        // implementation
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/doctor/{docName}"
    }
    resource function updateDoctorData(http:Caller caller, http:Request request, string docName) {
         // implementation
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/doctor/{docName}"
    }
    resource function deleteDoctorData(http:Caller caller, http:Request request, string docName) {
        // implementation
    }
```

Then let's implement the logic related to querying the database for a defined query inside `sql_utilities.bal` file.

```ballerina
public function getDoctorDetails(string speciality) returns json|error {

        // implementation
        // returns a JSON or error
}

public function addDoctorDetails(string name, string hospital, string speciality, string availability, int charge) returns sql:UpdateResult|error {

        // implementation
        // returns sql:UpdateResult|error
}

public function updateDoctorDetails(string name ,string hospital, string speciality, string availability, int charge) returns sql:UpdateResult|error {

        // implementation
        // returns sql:UpdateResult|error
}

public function deleteDoctorDetails(string name) returns sql:UpdateResult|error {

        // implementation
        // returns sql:UpdateResult|error
}
```

Finally we will define the the MySQL queries inside `sql_queries.bal` file that is used to query the Doctors table.

```ballerina
final string QUERY_SELECT_DOCTOR_INFORMATION =
        // select query

final string QUERY_INSERT_DOCTOR_INFORMATION =
        // insert query

final string QUERY_UPDATE_DOCTOR =
        //  update query

final string QUERY_DELETE_DOCTOR_INFORMATION =
       // delete query

```

### Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

#### Deploying Locally

To deploy locally, navigate to `routing-requests-based-on-message-content/guide`, and execute the following command.

```
$ ballerina build
```

This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder.
You can run them with the command:

```
$ ballerina run <Executable_File_Name>
```

#### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container. Ballerina language includes a `Ballerina_Docker_Extension`, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

### Testing

#### Starting the Database Service

After adding the implementation, we can start the RESTful service as below.

```
$ ballerina run data_service.bal
```

The service starts and you will see the following output.

```
$ Initiating service(s) in 'data_service'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9092
```

#### Invoking the Database Service

Now we can test the functionality of the database service by sending HTTP requests for each order management operation. The following are sample JSON requests that you can use to test each operation of the database service.

**Retrieve Doctor Information**

We can send the following request to the service by defining the speciality as a URL parameter.

```json
 http://localhost:9092/hospitalMgtService/doctor/surgery
```

Response:

```json
{
  "name": "thomas collins",
  "hospital": "grand oak community hospital",
  "availability": "9.00 a.m - 11.00 a.m",
  "speciality": "surgery",
  "charge": 7000
}
```

**Insert a new doctor's information**

Request:

```json
{
  "docName": "Jacob Black",
  "hospital": "grand oak community hospital",
  "availability": "9.00 a.m - 11.00 a.m",
  "speciality": "Cardiology",
  "charge": 10000
}
```

Response:

```json
"Insert successful"
```

**Update a doctor's information**

We can send the following request to the service by defining the name of the doctor whose information is needed to be updated as a URL parameter along with the payload.

Request :

```json
http://localhost:9092/hospitalMgtService/doctor/thomas kirk
```

Payload :

```json
{
  "hospital": "'willow gardens general hospital'",
  "availability": "7.30 a.m - 11.00 a.m",
  "speciality": "Surgery",
  "charge": 3000
}
```

Response :

```json
"Update successful"
```

**Delete a doctor's information**

```json
http://localhost:9092/hospitalMgtService/doctor/thomas kirk
```

Response :

```json
"Delete successful"
```
