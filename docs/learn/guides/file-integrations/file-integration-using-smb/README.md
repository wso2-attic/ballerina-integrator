# File Integration using Samba

The WSO2 Samba Connector enables you to connect to a Samba server and perform operations on files and folders stored on the 
server. These operations include basic file operations such as reading, updating, and deleting files, and listening to 
the server to invoke operations when a file is created or deleted.

> In this guide you will learn how to use the WSO2 Samba Connector to create an SMB listener service using Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)

## What you'll Build

To understand how to build a service to listen to a Samba server, let's consider the use case of a data center that uses 
a Samba server to store data files. When a new file is added to the server, the SMB listener will read the file and add 
the file name and size to a map, and when the file is deleted from the server, it will remove the entry from the map. 

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

The above package structure will be created for you. Create the `smb_listener.bal` file in the Ballerina module.

### Developing the SMB listener service

Let's start implementation by importing the WSO2 Samba Connector in the `smb_listener.bal` file you just created.

```ballerina
import wso2/smb;
```

Then add the configuration for file type and file location to listen to.

 ```ballerina
type Config record {
    string fileNamePattern;
    string filePath;
};

Config conf = {
    fileNamePattern: config:getAsString("SMB_FILE_NAME_PATTERN"),
    filePath: config:getAsString("SMB_LISTENER_PATH")
};
```

Create an SMB listener instance by defining the configuration.

```ballerina
listener smb:Listener dataFileListener = new({
    protocol: smb:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("SMB_USERNAME"),
            password: config:getAsString("SMB_PASSWORD")
        }
    },
    path: conf.filePath,
    fileNamePattern: conf.fileNamePattern
    pollingInterval: config:getAsInt("SMB_POLLING_INTERVAL"),
});
```

Then implement the SMB client endpoint to do the file processing.
     
```ballerina
smb:ClientEndpointConfig smbConfig = {
    protocol: smb:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    secureSocket: {
     basicAuth: {
         username: config:getAsString("SMB_USERNAME"),
         password: config:getAsString("SMB_PASSWORD")
     }
    }
};

smb:Client smbClient = new(smbConfig);
```

Create the service to listen to the SMB server. 

```ballerina
service dataFileService on dataFileListener {
    resource function processDataFile(smb:WatchEvent fileEvent) {

        foreach smb:FileInfo file in fileEvent.addedFiles {
            log:printInfo("Added file path: " + file.path);
            processNewFile(file.path);
        }
        foreach string file in fileEvent.deletedFiles {
            log:printInfo("Deleted file path: " + file);
            processDeletedFile(file.path);
        }
    }
}
```

Declare a map to store file names and sizes.

```ballerina
map<int> fileMap = {};
```

Now, implement the processing of added and deleted files.

```ballerina
function processNewFile(string filePath) {
    int|error fileSize = smbClient -> size(filePath);
    if(fileSize is int){
        fileMap[filePath] = response;
        log:printInfo("Added file: " + filePath + " - " + fileSize.toString());
    } else {
        log:printError("Error in getting file size", response);
    }
}

function processDeletedFile(string filePath) {
    if(fileMap.hasKey(filePath)){
        fileMap.remove(filePath);
        log:printInfo("Deleted file: " + filePath);
    }
}
```

## Testing

### Invoking the service

Start the Samba server you will listen to before starting the listener service.

Navigate to `file-integration-using-smb` and run the following command to start the listener service in `smb_listener.bal`.

```bash
   $ ballerina run smb_listener
```

Add and delete files in the Samba server and check the logs to verify whether the service is working as expected.

## Deployment

After the development process, you can deploy the services using below methods by selecting as you wish.

### Deploying locally

Navigate to `file-integration-using-smb` and run the following command to build the Ballerina executables.

```bash
    $ ballerina build
```

Or use the following command to run the module.  

```bash
    $ ballerina run smb_listener
```

The successful execution of a service will show us something similar to the following output.
```
Compiling source
        wso2/smb_listener:0.1.0

Creating balos
        target/balo/smb_listener-2019r3-java8-0.1.0.balo
```
