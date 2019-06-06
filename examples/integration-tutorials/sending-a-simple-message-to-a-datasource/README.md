# sending-a-simple-message-to-a-datasource

This example demonstrates how to expose mysql databse as a service in Ballerina.

## What you'll build

In this example, let's use a real world scenario where opeartions related to Doctors for easy understanding. Here we can carry out the following actions.

* Insert details about the doctors that can be consulted by a patient   
* Update doctors' information
* Delete records about a particular doctor
* Retrieve the details about doctors by specifying the speciality
        list of doctors the hospital, availability and consultant fee of doctors for the speciality given by the user

## Prerequisites

* Ballerina Distribution
* A Text Editor or an IDE <br/>
    Tip: For a better development experience, install one of the following Ballerina IDE plugins: VSCode, IntelliJ IDEA
* MySQL
* JDBC driver <br/>
    Copy the downloaded JDBC driver jar file into the<BALLERINA_HOME>/bre/lib folder
* Run the Doctors.sql script inside resources folder  create the required table   and insert data.

## Implementation

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
  └──sending-a-simple-message-to-a-datasource
    └── sqlDataService
        ├── ballerina.conf
        └── dbInteraction
             ├── dataService.bal
             ├── sqlUtilities.bal
             ├── sqlQueries.bal
             └── sqlServiceConstants.bal
```


        
Create the above directories in your local machine and also create empty .bal files.

Then open the terminal and navigate to sqlDataService and run Ballerina project initializing toolkit.

   $ ballerina init

### Implementation

Let's get started with implementing the services perform database transactions.

1. First we have to define the mysql endpoint. Here we are reading data from the ballerina.conf file where the host, port, database name, user name and password is defined.  

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
2. Define the http listener port as follows.
   ```ballerina
   listener http:Listener doctorEP = new(9095);
   ```

3. Add the base path.

    ```ballerina
    @http:ServiceConfig {
        basePath: "/hello"
    }
    ```

4. Following files describe the skeleton of the dataService.bal, sqlUtilities.bal, sqlQueries.bal files.

First let's define the service in dataService.bal.

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

Then let's implement the logic related to querying the database for a defined query inside sqlUtilities.bal file.

```ballerina
public function getDoctorDetails(string speciality) returns json|error {

        // implementation
        //returns a json or error
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
Finally we'll define the the mysql queries inside sqlQueries.bal file which is used to query the Doctors table.

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

## Invoking the service

To test the functionality of the dbTransactions RESTFul service, send HTTP requests for each order management operation.<br/>
Following are sample json requests that you can use to test each operation of the dbTransactions service.

###### Retrieve Doctor Information

We can send the following request to the service by defining the speciality as a URL parameter.

```json 
 http://localhost:9095/hello/doctor/surgery 
 ```

Output:

```json
{
    "name": "thomas collins",
    "hospital": "grand oak community hospital",
    "availability": "9.00 a.m - 11.00 a.m",
    "speciality": "surgery",
    "charge": 7000
},
```
###### Insert a new doctor's information

Request:
```json
{
    "docName" : "Jacob Black",
    "hospital": "grand oak community hospital",
    "availability": "9.00 a.m - 11.00 a.m",
    "speciality": "Cardiology",
    "charge": 10000	
}
```
Output:
```json
"Insert successful"
```

###### Update a doctor's information

We can send the following request to the service by defining the name of the doctor whose information is needed to be updated as a URL parameter along with the payload.

Request :

```json
http://10.100.0.71.:9095/hello/doctor/thomas kirk
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
Output :
```json
"Update successful"
```

###### Delete a doctor's information

```json 
http://10.100.0.71.:9095/hello/doctor/thomas kirk
```

Output :
```json
"Delete successful"
```

