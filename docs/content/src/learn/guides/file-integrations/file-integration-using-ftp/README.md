# File Integration using FTP

The WSO2 FTP Connector enables you to connect to an FTP server and perform operations on files and folders stored on the 
server. These operations include basic file operations such as reading, updating, and deleting files, and listening to 
the server to invoke operations when a file is created or deleted.

> In this guide you will learn how to use the WSO2 FTP Connector to create an FTP listener service using Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you'll Build

To understand how to build a service to listen to an FTP server, let's consider the use case of a data center that uses 
an FTP server to store data files. When a new file is added to the server, the FTP listener will read the file and add 
the file name and size to a map, and when the file is deleted from the server, it will remove the entry from the map. 

![File integration using FTP](/src/ftp_listener/resources/file-integration-using-ftp.png)

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina IDE plugin for [VS Code](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina)
- An FTP Server (See [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04) on how to setup an FTP server)

## Implementation
> If you want to skip the basics, you can download the GitHub repo and directly move to the "Testing" section by skipping the "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
file-integration-using-ftp
    └── src
       └── ftp_listener
           └── ftp_listener.bal
```

Create the Ballerina project `file-integration-using-ftp` and add the `ftp_listener` module using the below commands. 

```bash
    $ ballerina new file-integration-using-ftp
    $ cd file-integration-using-ftp
    $ ballerina add ftp_listener
```

The above package structure will be created for you. Create the `ftp_listener.bal` file inside the Ballerina module.

### Developing the FTP listener service

Let's start implementation by importing the WSO2 FTP Connector in the `ftp_listener.bal` file which you just created. 
This will pull the FTP Connector from Ballerina Central.

```ballerina
import wso2/ftp;
```

Next, let's create an FTP Listener instance by defining the configuration in the `Ballerina.conf` file. The `FTP_HOST` 
is the IP address of the FTP server, while the `FTP_USERNAME` and `FTP_PASSWORD` are credentials of a user that has permission 
to access the FTP server. The `FTP_HOST` is the port used to connect with the server, of which the default value is `21`.

Then you can add the configurations for the type of files the listener should listen for. For instance, if listener 
should be invoked for text files, the config for `FTP_FILE_NAME_PATTERN` should be set as `(.*).txt`. Next, add 
the location to poll for files and how frequently the listener should poll for files, using the values 
`FTP_LISTENER_PATH` and `FTP_POLLING_INTERVAL`respectively.

<!-- INCLUDE_CODE_SEGMENT: { file: src/ftp_listener/ftp_listener.bal, segment: segment_1 } -->

Create the service to listen to the FTP server using the above listener. When files are added or deleted on the server, 
this service will be invoked, and the files will be processed.

<!-- INCLUDE_CODE_SEGMENT: { file: src/ftp_listener/ftp_listener.bal, segment: segment_2 } -->

Then implement the FTP Client, which will connect to the FTP server and get the details of new files to process. 
     
<!-- INCLUDE_CODE_SEGMENT: { file: src/ftp_listener/ftp_listener.bal, segment: segment_3 } -->

Declare a map to store the details of processed files.

```ballerina
map<int> fileMap = {};
```

Now, implement the processing of added and deleted files. When files are added to the server, the FTP client will 
retrieve the file size from the server, and the file name and its size will be added to the `fileMap`. When a file is 
removed from the server, the file will be removed from the map.

<!-- INCLUDE_CODE_SEGMENT: { file: src/ftp_listener/ftp_listener.bal, segment: segment_4 } -->

## Testing

### Invoking the service

To begin with invoking the service, start the FTP server. 

Navigate to `file-integration-using-ftp` directory and run the following command to build the listener service in `ftp_listener.bal`.

```bash
   $ ballerina build -a 
```

The successful build of a service will show us something similar to the following output.

```
Compiling source
        wso2/ftp_listener:0.1.0

Creating balos
        target/balo/ftp_listener-2019r3-java8-0.1.0.balo
```

This will create the Ballerina executables inside the `/target` directory.

Then run the jar file created in the above step.

```bash
   $ java -jar target/bin/ftp_listener.jar --b7a.config.file=src/ftp_listener/resources/ballerina.conf 
```

Add and delete files in the FTP server, and check the logs to verify whether the service is working as expected.
