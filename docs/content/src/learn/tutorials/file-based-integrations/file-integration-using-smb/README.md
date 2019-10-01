# File Integration using Samba

The WSO2 SMB Connector enables you to connect to a Samba server and perform operations on files and folders stored on the 
server. These operations include basic file operations such as reading, updating, and deleting files, and listening to 
the server to invoke operations when a file is created or deleted.

> In this guide you will learn how to use the WSO2 SMB Connector to create a Samba listener service using Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you'll Build

To understand how to build a service to listen to a Samba server, let's consider the use case of a data center that uses 
a Samba server to store data files. When a new file is added to the server, the Samba listener will read the file and add 
the file name and size to a map, and when the file is deleted from the server, it will remove the entry from the map. 

![File integration using Samba](/src/smb_listener/resources/file-integration-using-smb.png)

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina IDE plugin for [VS Code](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina)
- A Samba Server (See [here](https://linuxize.com/post/how-to-install-and-configure-samba-on-ubuntu-18-04) on how to setup a Samba server)

## Implementation
> If you want to skip the basics, you can download the GitHub repo and directly move to the "Testing" section by skipping the "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
file-integration-using-smb
    └── src
       └── smb_listener
           └── smb_listener.bal
```

Create the Ballerina project `file-integration-using-smb` and add the `smb_listener` module using the below commands. 

```bash
    $ ballerina new file-integration-using-smb
    $ cd file-integration-using-smb
    $ ballerina add smb_listener
```

The above package structure will be created for you. Create the `smb_listener.bal` file inside the Ballerina module.

### Developing the Samba listener service

Let's start implementation by importing the WSO2 SMB Connector in the `smb_listener.bal` file which you just created. 
This will pull the SMB Connector from Ballerina Central.

```ballerina
import wso2/smb;
```

Next, let's create a Samba Listener instance by defining the configuration in the `Ballerina.conf` file. The `SMB_HOST` 
is the IP address of the Samba server, while the `SMB_USERNAME` and `SMB_PASSWORD` are credentials of a user that has permission 
to access the Samba server. The `SMB_HOST` is the port used to connect with the server, of which the default value is `21`.

Then you can add the configurations for the type of files the listener should listen for. For instance, if listener 
should be invoked for text files, the config for `SMB_FILE_NAME_PATTERN` should be set as `(.*).txt`. Next, add 
the directory or location in Samba share to poll for files and how frequently the listener should poll for files, using the values 
`SMB_LISTENER_PATH` and `SMB_POLLING_INTERVAL`respectively.

<!-- INCLUDE_CODE_SEGMENT: { file: src/smb_listener/smb_listener.bal, segment: segment_1 } -->

Create the service to listen to the Samba server using the above listener. When files are added or deleted on the server, 
this service will be invoked, and the files will be processed.

<!-- INCLUDE_CODE_SEGMENT: { file: src/smb_listener/smb_listener.bal, segment: segment_2 } -->

Then implement the Samba Client, which will connect to the Samba server and get the details of new files to process. 
     
<!-- INCLUDE_CODE_SEGMENT: { file: src/smb_listener/smb_listener.bal, segment: segment_3 } -->

Declare a map to store the details of processed files.

```ballerina
map<int> fileMap = {};
```

Now, implement the processing of added and deleted files. When files are added to the server, the Samba client will 
retrieve the file size from the server, and the file name and its size will be added to the `fileMap`. When a file is 
removed from the server, the file will be removed from the map.

<!-- INCLUDE_CODE_SEGMENT: { file: src/smb_listener/smb_listener.bal, segment: segment_4 } -->

## Testing

### Invoking the service

To begin with invoking the service, start the Samba server. 

Navigate to `file-integration-using-smb` directory and run the following command to build the listener service in `smb_listener.bal`.

```bash
   $ ballerina build -a 
```

The successful build of a service will show us something similar to the following output.

```
Compiling source
        wso2/smb_listener:0.1.0

Creating balos
        target/balo/smb_listener-2019r3-java8-0.1.0.balo
```

This will create the Ballerina executables inside the `/target` directory.

Then run the jar file created in the above step.

```bash
   $ java -jar target/bin/smb_listener.jar --b7a.config.file=src/smb_listener/resources/ballerina.conf 
```

Add and delete files in the Samba server, and check the logs to verify whether the service is working as expected.
