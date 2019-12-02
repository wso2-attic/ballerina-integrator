# File Integration using FTP

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on how to use the WSO2 FTP Connector to create an FTP listener service using Ballerina. You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

The WSO2 FTP Connector enables you to connect to an FTP server and perform operations on files and folders stored on the 
server. These operations include basic file operations such as reading, updating, and deleting files, and listening to 
the server to invoke operations when a file is created or deleted.

## What you'll Build

To understand how to build a service to listen to an FTP server, let's consider the use case of a data center that uses 
an FTP server to store data files. When a new file is added to the server, the FTP listener will read the file and add 
the file name and size to a map, and when the file is deleted from the server, it will remove the entry from the map. 

![File integration using FTP](../../../../assets/img/file-integration-using-ftp.png)

<!-- INCLUDE_MD: ../../../../tutorial-prerequisites.md -->
* An FTP Server (See [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04) on how to setup an FTP server)

<!-- INCLUDE_MD: ../../../../tutorial-get-the-code.md -->

## Implementation
> If you want to skip the basics, you can download the GitHub repo and directly move to the "Testing" section by skipping the "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
file-integration-using-ftp
    └── src
       └── file_integration_using_ftp
           └── ftp_listener.bal
```

Create the Ballerina project `file-integration-using-ftp` and add the `file_integration_using_ftp` module using the below commands.

```bash
$ ballerina new file-integration-using-ftp
$ cd file-integration-using-ftp
$ ballerina add file_integration_using_ftp
```

The above package structure will be created for you. 

Add project configuration file by creating `ballerina.conf` file under the root path of the project structure. <br/>
This file should have the following configurations.
```
FTP_HOST=""
FTP_LISTENER_PORT=21
FTP_USERNAME=""
FTP_PASSWORD=""
FTP_FILE_NAME_PATTERN="(.*).txt"
FTP_LISTENER_PATH=""
FTP_POLLING_INTERVAL=
```

Create the `ftp_listener.bal` file inside the Ballerina module.

### Developing the FTP listener service

Let's start implementation by importing the WSO2 FTP Connector in the `ftp_listener.bal` file which you just created. 
This will pull the FTP Connector from Ballerina Central.

```ballerina
import wso2/ftp;
```

Next, let's create an FTP Listener instance by defining the configuration in the `Ballerina.conf` file. The `FTP_HOST` 
is the IP address of the FTP server, while the `FTP_USERNAME` and `FTP_PASSWORD` are credentials of a user that has permission 
to access the FTP server. The `FTP_LISTENER_PORT` is the port used to connect with the server, of which the default value is `21`.

Then you can add the configurations for the type of files the listener should listen for. For instance, if listener 
should be invoked for text files, the config for `FTP_FILE_NAME_PATTERN` should be set as `(.*).txt`. Next, add 
the location to poll for files and how frequently the listener should poll for files, using the values 
`FTP_LISTENER_PATH` and `FTP_POLLING_INTERVAL`respectively.

<!-- INCLUDE_CODE_SEGMENT: { file: src/file_integration_using_ftp/ftp_listener.bal, segment: segment_1 } -->

Create the service to listen to the FTP server using the above listener. When files are added or deleted on the server, 
this service will be invoked, and the files will be processed.

<!-- INCLUDE_CODE_SEGMENT: { file: src/file_integration_using_ftp/ftp_listener.bal, segment: segment_2 } -->

Then implement the FTP Client, which will connect to the FTP server and get the details of new files to process. 
     
<!-- INCLUDE_CODE_SEGMENT: { file: src/file_integration_using_ftp/ftp_listener.bal, segment: segment_3 } -->

Declare a map to store the details of processed files.

```ballerina
map<int> fileMap = {};
```

Now, implement the processing of added and deleted files. When files are added to the server, the FTP client will 
retrieve the file size from the server, and the file name and its size will be added to the `fileMap`. When a file is 
removed from the server, the file will be removed from the map.

<!-- INCLUDE_CODE_SEGMENT: { file: src/file_integration_using_ftp/ftp_listener.bal, segment: segment_4 } -->

## Testing

### Invoking the service

To begin with invoking the service, start the FTP server. 

Navigate to `file-integration-using-ftp` directory and run the following command to build the listener service in `ftp_listener.bal`.

```bash
$ ballerina build file_integration_using_ftp
```

The successful build of a service will show us something similar to the following output.

```
Compiling source
        wso2/file_integration_using_ftp:0.1.0

Creating balos
        target/balo/file_integration_using_ftp-2019r3-java8-0.1.0.balo
```

This will create the Ballerina executables inside the `/target` directory.

Then run the jar file created in the above step.

```bash
$ java -jar target/bin/file_integration_using_ftp.jar --b7a.config.file=src/file_integration_using_ftp/resources/ballerina.conf
```

Add and delete files in the FTP server, and check the logs to verify whether the service is working as expected.
