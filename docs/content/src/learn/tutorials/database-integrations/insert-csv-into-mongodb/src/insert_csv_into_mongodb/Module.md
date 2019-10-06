Guide on Importing CSV Data to MongoDB.

# Guide Overview

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on importing CSV file having contacts into MongoDB using FTP connector.

`wso2/mongodb` module allows you to perform CRUD operations on Mongo DB.<br/>
The `wso2/ftp` module provides an FTP client and an FTP server listener implementation to facilitate an FTP connection
to a remote location. You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) Github repository.

## What you'll build

This application listens to a remote FTP location and when a CSV file is added to that FTP location, it will fetch the CSV file, read its contents and insert the content into Mongo DB. Then a
success message is logged if the operation is successful.

![inserting csv data to mongo db](resources/mongo-insert.jpg)

## Implementation
The Ballerina project is created for the integration use case explained above. Please follow the steps given below. You can learn about the Ballerina project and module by following the [documentation on creating a project and using modules](../../../../develop/using-modules/).

Create a project.
```bash
$ ballerina new insert-csv-into-mongodb
```
Navigate to the insert-csv-into-mongodb directory.

Add a module.
```bash
$ ballerina add insert_csv_into_mongodb
```

Set up remote FTP server and obtain the following credentials.
   - FTP Host
   - FTP Port
   - FTP Username
   - FTP Password
   - Path in the FTP server to which the CSV files are added

Add the `insert-csv-into-mongodb/src/insert_csv_into_mongodb/resources/contacts.csv` file to the FTP path you mentioned above.

Add project configuration file by creating `ballerina.conf` file under the root path of the project structure. <br/>
This file should have following Mongo DB and FTP configurations.

```
MONGO_HOST="<MongoDB_Host>"
MONGO_DB_NAME="<MongoDB_Name>"
MONGO_USERNAME="<MongoDB_Username>"
MONGO_PASSWORD="<MongoDB_Password>"
FTP_HOST="<FTP_Host>"
FTP_PORT=<FTP_PORT>
FTP_USERNAME="<FTP_Username>"
FTP_PASSWORD="<FTP_Password>"
FTP_PATH="<FTP_Location>""
```

Write your integration.
You can open the project with VS Code. The implementation will be written in the `main.bal` file.

Here `ftpServerConnector` service is running on `remoteServer`, which listens to the configured FTP server location.
When a CSV file is added to the FTP server, the file content will be retrieved and inserted into Mongo DB.


## Run the integration

First, let’s build the module. While being in the insert-csv-into-mongodb directory, execute the following command.

```bash
$ ballerina build insert_csv_into_mongodb
```

The build command would create an executable .jar file. Now run the .jar file created in the above step to execute the .jar.

```bash
$ java -jar target/bin/insert_csv_into_mongodb.jar
```

You will see the following log after successfully importing the contacts.csv file to Mongo DB.
```
2019-09-27 12:40:40,882 INFO  [wso2/insert_csv_into_mongodb] - Added file path  /home/ftp-user/in/mongo/contacts.csv to FTP location
2019-09-27 12:40:40,953 INFO  [wso2/insert_csv_into_mongodb] - Successfully inserted data to mongo db
```
