# Google Spreadsheet Connector Service

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the 
support of connectors. In this guide, we are mainly focusing on Google Spreadsheet Connector Service. 

The `wso2/gsheets4` module allows you to perform the following operations.

- Create a new spreadsheet
- Create a new worksheet
- View a spreadsheet
- Add values into a worksheet
- Get values from worksheet
- Retrieving values of a column
- Retrieving values of a row
- Adding value into a cell
- Retrieving value of a cell
- Retrieving value of a cell

This example explains how to use Google Spreadsheet Connector to perform the above operations.

You can find other integrations modules from [wso2-ballerina](https://github.com/wso2-ballerina) GitHub organization.

## What you'll build

This example explains how to use the Google Spreadsheet client to connect with the Google Spreadsheet Connector instance and perform the 
following operations:

![working with Google Spreadsheet Connector](../../../../../assets/img/)

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

A Ballerina project is created for the integration use case explained above. Please follow the steps given 
below to create the project and modules. You can learn about the Ballerina project and modules in this 
[guide](https://ei.docs.wso2.com/en/latest/ballerina-integrator/develop/using-modules/#creating-a-project).

#### 1. Create a new project.

```bash
$ ballerina new working-with-googlespreadsheet-service
```

#### 2. Create a module.

```bash
$ ballerina add googlespreadsheet_service
```

The project structure is created as indicated below.

```
working-with-googlespreadsheet-service
    ├── Ballerina.toml
    └── src
        └── googlespreadsheet_service
            ├── Module.md
            ├── main.bal
            ├── resources
            └── tests
                └── resources
```

#### 3. Set up credentials for accessing Amazon S3

- Visit [Credentials](https://console.developers.google.com/apis/credentials) to get client ID, client secret and other required credentials from Google.

- You can also follow [Get Credentials for Google Spreadsheet](https://docs.wso2.com/display/IntegrationCloud/Get+Credentials+for+Google+Spreadsheet) to get the required credentials for this application.

#### 4. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the obtained Amazon S3 configurations to the file.

```
ACCESS_TOKEN="<Acces_token>"
CLIENT_ID="<Client_id">
CLIENT_SECRET="<Client_secret>"
REFRESH_TOKEN="<Refresh_token>"
REFRESH_URL = "<Refresh_URL>"
LISTENER_PORT = Listener_port>
BASE_PATH = "/spreadsheets"
```

#### 5. Write the integration
Open the project with VS Code. The integration implementation is written in the `src/googlespreadsheet_service/main.bal` file.

<!-- INCLUDE_CODE: src/googlespreadsheet_service/main.bal -->

## Testing 

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build googlespreadsheet_service
```

This creates the executables. Now run the `googlespreadsheet_servicet.jar` file created in the above step.

```bash
$ java -jar target/bin/googlespreadsheet_service.jar
```

You will see the following service log after successfully invoking the service.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```

### 1. Testing create a new spreadsheet
 ```bash
 curl -v -X POST http://localhost:9090/spreadsheets/<SPREADSHEET_NAME>
```
e.g.   
```bash 
curl -v -X POST http://localhost:9090/spreadsheets/firstSpreadsheet
```
### 2. Testing adding a new worksheet
  ```bash
        curl -v -X POST http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_NAME>

        e.g: curl -v -X POST http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet
   ```
        
### 3. Testing viewing a spreadsheet
```bash
curl -X GET http://localhost:9090/spreadsheets/<SPREADSHEET_ID>
```
e.g.
```bash
curl -X GET http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY
```

### 4. Testing adding values into a worksheet
```bash
curl -H "Content-Type: application/json" \ -X PUT \ -d '[["Name", "Score"], ["Keetz", "12"], ["Niro", "78"], ["Nisha", "98"], ["Kana", "86"]]'\http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>
```
e.g:
```bash
curl -H "Content-Type: application/json" \-X PUT \ -d '[["Name", "Score"], ["Keetz", "12"], ["Niro", "78"], ["Nisha", "98"], ["Kana", "86"]]' \ http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/A1/B5
```       
 
### 5. Testing  get values from worksheet
```bash\
curl -X GET http://localhost:9090/spreadsheets/worksheet/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>
```
e.g: 
```bash
curl -X GET http://localhost:9090/spreadsheets/column/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/B
```
  
### 6. Testing retrieving values of a column
```bash
curl -X GET http://localhost:9090/spreadsheets/column/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<COLUMN_NAME>
```

### 7. Testing retrieving values of a row
```bash
curl -X GET http://localhost:9090/spreadsheets/row/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<COLUMN_NAME>/<ROW_NAME>
```
e.g: 
```bash        
curl -X GET http://localhost:9090/spreadsheets/row/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/2
```

### 8. Testing  adding value into a cell
```bash
curl -H "Content-Type: text/plain" \ -X PUT \ -d 'Test Value' \http://localhost:9090/spreadsheets/cell/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>
```
e.g:
```bash
curl -H "Content-Type: text/plain" \ -X PUT \ -d 'Test Value' \
http://localhost:9090/spreadsheets/cell/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/C/2
```        

### 9. Testing  retrieving value of a cell
```bash
curl -X GET http://localhost:9090/spreadsheets/cell/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>
```
e.g: 
```bash
curl -X GET http://localhost:9090/spreadsheets/cell/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/C/2
```
 
### 10. Testing deleting a worksheet
```bash
curl -X DELETE http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_ID>
```
e.g:
```bash
 curl -X DELETE http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/1636241809
 ```