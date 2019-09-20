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
- [Deployment](#deployment)

## What you'll Build

To understand how to build a service to listen to an FTP server, let's consider the use case of a data center that uses 
an FTP server to store data files. When a new file is added to the server, the FTP listener will read the file and add 
the file name and size to a map, and when the file is deleted from the server, it will remove the entry from the map. 

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
    ├── src
       └── ftp_listener
           └── ftp_listener.bal
```

Create the Ballerina project `file-integration-using-ftp` and add the `ftp_listener` module using the below commands. 

```bash
    $ ballerina new file-integration-using-ftp
    $ cd file-integration-using-ftp
    $ ballerina add ftp_listener
```

The above package structure will be created for you. Create the `ftp_listener.bal` file in the Ballerina module.

### Developing the FTP listener service

Let's start implementation by importing the WSO2 FTP Connector in the `ftp_listener.bal` file you just created.

```ballerina
import wso2/ftp;
```

Then add the configuration for file type and file location to listen to.

 ```ballerina
type Config record {
    string fileNamePattern;
    string filePath;
};

Config conf = {
    fileNamePattern: config:getAsString("FTP_FILE_NAME_PATTERN"),
    filePath: config:getAsString("FTP_LISTENER_PATH")
};
```

Create an FTP listener instance by defining the configuration.

```ballerina
listener ftp:Listener dataFileListener = new({
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USERNAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    },
    path: conf.filePath,
    fileNamePattern: conf.fileNamePattern
    pollingInterval: config:getAsInt("FTP_POLLING_INTERVAL"),
});
```

Then implement the FTP client endpoint to do the file processing.
     
```ballerina
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
     basicAuth: {
         username: config:getAsString("FTP_USERNAME"),
         password: config:getAsString("FTP_PASSWORD")
     }
    }
};

ftp:Client ftpClient = new(ftpConfig);
```

Create the service to listen to the FTP server. 

```ballerina
service dataFileService on dataFileListener {
    resource function processDataFile(ftp:WatchEvent fileEvent) {

        foreach ftp:FileInfo file in fileEvent.addedFiles {
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
    int|error fileSize = ftpClient -> size(filePath);
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

Start the FTP server you will listen to before starting the listener service.

Navigate to `file-integration-using-ftp` and run the following command to start the listener service in `ftp_listener.bal`.

```bash
   $ ballerina run ftp_listener
```

Add and delete files in the FTP server and check the logs to verify whether the service is working as expected.

## Deployment

After the development process, you can deploy the services using below methods by selecting as you wish.

### Deploying locally

Navigate to `file-integration-using-ftp` and run the following command to build the Ballerina executables.

```bash
    $ ballerina build
```

Or use the following command to run the module.  

```bash
    $ ballerina run ftp_listener
```

The successful execution of a service will show us something similar to the following output.
```
Compiling source
        wso2/ftp_listener:0.1.0

Creating balos
        target/balo/ftp_listener-2019r3-java8-0.1.0.balo
```
