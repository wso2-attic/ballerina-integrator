Template for File Integration using the SMB Connector

# File Integration using the SMB Connector

This is a template for the [File Integration Using Samba tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/file-based-integrations/file-integration-using-smb/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `file_integration_using_smb` template from Ballerina Central.

```
$ ballerina pull wso2/file_integration_using_smb
```

Create a new project.

```bash
$ ballerina new file-integration-using-smb
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/file_integration_using_smb file_integration_using_smb
```

This automatically creates file_integration_using_smb service for you inside the `src` directory of your project.  

## Testing

### Before you begin

### 1. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the SMB server configurations to the file.

```
SMB_HOST="<IP address of the Samba server>"
SMB_USERNAME="<Username of the Samba server >"
SMB_PASSWORD="<Password of the Samba server>"
SMB_LISTENER_PORT="<port used to connect with the server (default value 21)>"
SMB_FILE_NAME_PATTERN="<type of files the listener should listen for e.g.(.*).txt >"
SMB_LISTENER_PATH="<location to poll>"
SMB_POLLING_INTERVAL="<polling interval>"
```

### 2. Invoking the service

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build file_integration_using_smb
```

This creates the executables. Now run the `file_integration_using_smb.jar` file created in the above step. Path to the ballerina.conf file can be provided using the --b7a.config.file option.

```bash
$ java -jar target/bin/file_integration_using_smb.jar --b7a.config.file=path/to/ballerina.conf/file
```
