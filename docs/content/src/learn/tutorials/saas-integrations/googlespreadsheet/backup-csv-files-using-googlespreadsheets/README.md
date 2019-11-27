# Backup CSV Files Using Google Spreadsheets

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the 
support of connectors. In this guide, we are mainly focusing on how to use Google Spreadsheets Connector to backup CSV (Comma Separated Value) files in Google Spreadsheets. 
You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

## What you'll build
The following diagram illustrates the scenario:

![Message flow diagram image](../../../../../assets/img/googlespreadsheet.png)

Let's consider a scenario where a CSV file is uploaded to a newly created Google Spreadsheet. A new sheet is created in the spreadsheet with the current date as the sheet name. CSV content is added to the new sheet. The sheet is then read and the content is displayed on the console to the user.

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

- You need to obtain credentials to access Google Spreadsheet in order to configure a Google Spreadsheet client. Instructions on how to obtain the credentials for the Google Spreadsheet can be found [here](https://docs.wso2.com/display/IntegrationCloud/Get+Credentials+for+Google+Spreadsheet).

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation
The Ballerina project is created for the integration use case as explained above. Please follow the steps given below. You can learn about the Ballerina project and module in this [link](https://github.com/wso2-ballerina/module-googlespreadsheet). 

#### 1. Create a new project.
```bash
  $ ballerina new backup-csv-files-using-googlespreadsheets
```

#### 2. Create a module.
```bash
  $ ballerina add backup_csv_files
```

To implement the scenario in this guide, you can use the following package structure:

```shell
  backup-csv-files-using-googlespreadsheets
  ├── Ballerina.toml
  └── src
      └── backup_csv_files
          ├── Module.md
          └── uploader.bal
```

#### 3. Add the project configuration file
Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
The configuration file must have the following configurations

```
ACCESS_TOKEN="<Google Spreadsheet Access Token>"
CLIENT_ID="<Google Spreadsheet Client Id>"
CLIENT_SECRET="<Google Spreadsheet Client Secret>"
REFRESH_URL="<Refresh URL>"
REFRESH_TOKEN="<Refresh Token>"
``` 

#### 4. Write the integration.
Take a look at the code samples below to understand how to implement the integration scenario.

#### uploader.bal
The following code reads the contents of a CSV file and saves the data in a new Google Spreadsheet. The data is then read from the spreadsheet and displayed on the console.

<!-- INCLUDE_CODE: src/backup_csv_files/uploader.bal -->

## Testing
To build the module, navigate to the project root directory and execute the following command.

```bash
  ballerina build backup_csv_files
```

This command creates the executable jar file.

Now run the `backup_csv_files.jar` file created in the above step.

```bash
  java -jar target/bin/backup_csv_files.jar
```

This starts the service that reads the data from the `people.csv` files stored in the resources folder. You will notice that the contents of the file have been set in the Google Spreadsheet and the data will also display on the console.