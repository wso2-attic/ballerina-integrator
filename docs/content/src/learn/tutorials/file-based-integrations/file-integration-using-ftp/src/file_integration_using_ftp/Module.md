Template for File Integration using FTP Connector
# File Integration using the FTP Connector

This is a template for the [File Integration Using FTP tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/file-based-integrations/file-integration-using-ftp/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `file_integration_using_ftp` template from Ballerina Central.

```
$ ballerina pull wso2/file_integration_using_ftp
```

Create a new project.

```bash
$ ballerina new file-integration-using-ftp
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/file_integration_using_ftp file_integration_using_ftp
```

This automatically creates file_integration_using_ftp service for you inside the `src` directory of your project.  

## Testing

### Before you begin

### 1. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the FTP server configurations to the file.

```
FTP_HOST="<IP address of the FTP server>"
FTP_USERNAME="<Username of the FTP server >"
FTP_PASSWORD="<Password of the FTP server>"
FTP_LISTENER_PORT="<port used to connect with the server (default value 21)>"
FTP_FILE_NAME_PATTERN="<type of files the listener should listen for e.g.(.*).txt >"
FTP_LISTENER_PATH="<location to poll>"
FTP_POLLING_INTERVAL="<polling interval>"
```

### 2. Invoking the service

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build file_integration_using_ftp
```

This creates the executables. Now run the `file_integration_using_ftp.jar` file created in the above step. Path to the ballerina.conf file can be provided using the --b7a.config.file option.

```bash
$ java -jar target/bin/file_integration_using_ftp.jar --b7a.config.file=path/to/ballerina.conf/file
```
