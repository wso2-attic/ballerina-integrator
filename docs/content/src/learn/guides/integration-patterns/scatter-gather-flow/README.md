# Scatter-Gather Flow Control

## About

Scatter-Gather is an integration pattern where a request is sent to multiple recipients and each of the responses are aggregated and returned back to the client as a single response. This guide demonstrates a simple scatter-gather scenario where two files in an FTP location are read simultaneously, their contents aggregated and sent back to the client.

## What you'll build

We shall have a service ‘employeeDetails’ which accepts a client request and reads two different CSV files with employee details from an FTP server. It then converts the responses of each read to json, aggregates both the json and sends back to the client.

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina IDE plugin for [VS Code](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina)
- An FTP Server

## Implementation

* Create a new ballerina project named ‘scatter-gather-flow’.

```bash
$ ballerina new scatter-gather-flow
```

* Navigate to the directory scatter-gather-flow.

* Add a new module named ‘employee_details_service’ to the project.

```bash
$ ballerina add employee_details_service
```

* Open the project with VSCode. The project structure will be like the following.

```shell
.
├── Ballerina.toml
└── src
    └── employee_details_service
        ├── main.bal
        ├── Module.md
        ├── resources
        │   └── ballerina.conf
        └── tests
            ├── main_test.bal
            └── resources
```
We can remove the file `main_test.bal` at the moment, since we're not writing any tests for our service.

* Now let's create a file called `ballerina.conf` under the root path of the project structure. The file should have the following configurations.

```
FTP_HOST = "<ftp_host>"
FTP_PORT = <port>
FTP_USER = "<username>"
FTP_PASSWORD = "<password>"
```

The username and password are sensitive data. Therefore those should not be hard-coded. Ballerina supports encrypting sensitive data and uses them in the program.

```shell
$ ballerina encrypt
```

The execution of the encrypt action will ask for value and secret key. Once you provide input, it'll output the encrypted value that can directly be used in the config file.

```shell
Enter value:

Enter secret:

Re-enter secret to verify:

Add the following to the configuration file:
<key>="@encrypted:{aoIlSvOPeBEZ0COma+Wz2uWznlNn1IWz4StiWQCO6g4=}"

Or provide it as a command line argument:
--<key>=@encrypted:{aoIlSvOPeBEZ0COma+Wz2uWznlNn1IWz4StiWQCO6g4=}
```

Now we can use the encrypted value in the `ballerina.conf` file.

```
FTP_USER = "@encrypted:{aoIlSvOPeBEZ0COma+Wz2uWznlNn1IWz4StiWQCO6g4=}"
FTP_PASSWORD = "@encrypted:{aoIlSvOPeBEZ0COma+Wz2uWznlNn1IWz4StiWQCO6g4=}"
```

* Before writing the service, let's create two csv files `employees1.csv` and `employees2.csv` with the following content and upload to an FTP server.

```csv
empId,firstName,lastName,joinedDate
100,Lois,Walker,11/24/2003
101,Brenda,Robinson,7/27/2008
102,Joe,Robinson,8/3/2016
103,Diane,Evans,4/16/1999
104,Benjamin,Russell,7/25/2013
```

```csv
empId,firstName,lastName,joinedDate
105,Nancy,Baker,7/22/2005
106,Carol,Murphy,9/14/2016
107,Frances,Young,1/28/1983
108,Diana,Peterson,4/27/1994
109,Ralph,Flores,2/17/2014
```

* Now open the main.bal file and add the following content. This is going to be our integration logic.

```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/config;
import wso2/ftp;

ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USER"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};
ftp:Client ftpClient = new (ftpConfig);

json[] employees = [];

@http:ServiceConfig {
    basePath: "/organization"
}
service employeeDetails on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employees"
    }
    resource function getEmployees(http:Caller caller, http:Request req) {

        fork {
            worker w1 returns io:ReadableByteChannel {
                return checkpanic ftpClient->get("/home/ftp-user/in/employees1.csv");
            }
            worker w2 returns io:ReadableByteChannel {
                return checkpanic ftpClient->get("/home/ftp-user/in/employees2.csv");
            }
        }
        record {io:ReadableByteChannel w1; io:ReadableByteChannel w2;} results = wait {w1, w2};
        populateEmp(results.w1);
        populateEmp(results.w2);
        http:Response response = new;
        response.setJsonPayload(<@untainted>employees);
        error? respond = caller->respond(response);
    }
}

//populating the employees json array with employee rows
function populateEmp(io:ReadableByteChannel ch) {
    string[][] employeeRows = convertToStringArray(ch);
    foreach var i in 1 ... employeeRows.length() - 1 {
        json m = convertToJson(employeeRows[i]);
        employees[employees.length()] = m;
    }
}

//extracting a string array of arrays from a ReadableByteChannel
function convertToStringArray(io:ReadableByteChannel rbChannel) returns @tainted string[][] {
    io:ReadableCharacterChannel characters = new (rbChannel, "utf-8");
    io:ReadableCSVChannel csvChannel = new (characters);
    string[][] rows = [];
    while (csvChannel.hasNext()) {
        string[] currentRow = <string[]> checkpanic csvChannel.getNext();
        rows[rows.length()] = currentRow;
    }
    var closeResult = characters.close();
    return rows;
}

//converting a string array to required json format
function convertToJson(string[] empRow) returns json {
    json emp = {
        "empId": empRow[0],
        "firstName": empRow[1],
        "lastName": empRow[2],
        "joinedDate": empRow[3]
    };
    return emp;
}
```


## Run the Integration

* First let’s build the module. While being in the scatter-gather-flow directory, execute the following command.

```bash
$ ballerina build employee_details_service
```

This would create the executables without running the test cases. 

* Now run the jar file created in the above step.

```bash
$ java -jar target/bin/employee_details_service.jar
```
You will be prompted to enter the secret you used for encrypting the FTP username and password.

```bash
ballerina: enter secret for config value decryption:
```
Now we can see that the service has started on port 9090. 

* Let’s access this service by executing the following curl command.

```bash
$ curl http://localhost:9090/organization/employees
```

We shall get a json response like the following.

```json
[
   {
      "empId":"100",
      "firstName":"Lois",
      "lastName":"Walker",
      "joinedDate":"11/24/2003"
   },
   {
      "empId":"101",
      "firstName":"Brenda",
      "lastName":"Robinson",
      "joinedDate":"7/27/2008"
   },
   {
      "empId":"102",
      "firstName":"Joe",
      "lastName":"Robinson",
      "joinedDate":"8/3/2016"
   },
   {
      "empId":"103",
      "firstName":"Diane",
      "lastName":"Evans",
      "joinedDate":"4/16/1999"
   },
   {
      "empId":"104",
      "firstName":"Benjamin",
      "lastName":"Russell",
      "joinedDate":"7/25/2013"
   },
   {
      "empId":"105",
      "firstName":"Nancy",
      "lastName":"Baker",
      "joinedDate":"7/22/2005"
   },
   {
      "empId":"106",
      "firstName":"Carol",
      "lastName":"Murphy",
      "joinedDate":"9/14/2016"
   },
   {
      "empId":"107",
      "firstName":"Frances",
      "lastName":"Young",
      "joinedDate":"1/28/1983"
   },
   {
      "empId":"108",
      "firstName":"Diana",
      "lastName":"Peterson",
      "joinedDate":"4/27/1994"
   },
   {
      "empId":"109",
      "firstName":"Ralph",
      "lastName":"Flores",
      "joinedDate":"2/17/2014"
   }
]
```

