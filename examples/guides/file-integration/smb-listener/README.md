# Implementing smb listener with Ballerina

This example demonstrates how implement smb listener in Ballerina.

## What you'll build

In this example, we'll implement smb listener which will listen to a remote directory and periodically notify the file addition of the specified file pattern.

Then we can define the processing we need to upon the file content.

Finally we can move the processed file to the specified location or delete it.

## Prerequisites

* Ballerina Distribution
* A Text Editor or an IDE <br/>
    Tip: For a better development experience, install one of the following Ballerina IDE plugins: VSCode, IntelliJ IDEA
* Install ftp connectors by following the below steps.<br/>
1. Download correct distribution.zip from releases (we can get it from the link given below) that match with ballerina version. <br/>
https://github.com/wso2-ballerina/module-ftp<br/>
2. Unzip package distribution.<br/>
3. Run the install.<sh|bat> script to install the package. You can uninstall the package by running uninstall.<sh|bat>.  <br/>
* SMB server and client  

## Implementation

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
  └──file-integration
    └── smb-listener
        └── smb_listener.bal            
```
        
Create the above directories in your local machine and also create empty .bal files.

Then open the terminal and navigate to ftp-template and run Ballerina project initializing toolkit.

```ballerina
   $ ballerina init
```

### Implementation

Let's get started with implementing the ftp_listener.
1. First we have to import the ballerina ftp_module.

```ballerina
import wso2/ftp;
```
2. Define the union type of the actions that can be performed after processing the file.
Define ERROR type also as an error can also be returned if the file processing fails.

```ballerina
public const MOVE = "MOVE";
public const DELETE = "DELETE";
public const ERROR = "ERROR";

public type Operation  MOVE|DELETE|ERROR;

```
3. Define a record to get the following configurations for processing the file.

   ```ballerina
   type Config record {
        string fileNamePattern;
        string destFolder;
        string errFolder;
        Operation opr ;     
   };
   ```
  Following table explains the configuration parameters defined in the record.

| Parameter Name                                            | Description                                                                                                                            |
|-----------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| fileNamePattern                                           | Can be used to process only the files with the given fileNamePattern available at the specified file URI location.<br/> fileNamePattern can be given using a regular expression." |                                                                                                                                        |
| destFolder                                                | Where to move the files after processing if Operation is MOVE.                                                                         |
| errFolder                                                 | Where to move the files if processing fails.                                                                                           |
| opr                                                       | Whether to Move or Delete the file after processing.                                                                                   |

4. Give the configurations as inputs.

 ```ballerina
   Config conf = {
        fileNamePattern: ".*.xml",
        destFolder: "/sambaOutFolder",
        errFolder: "/sambaFaultFolder",
        srcFolder: "/sambaInFolder",
        opr: MOVE
};
```

5. Create a ftp listener instance by defining the configuration.

```ballerina
listener ftp:Listener remoteServer = new({
    protocol: ftp:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    pollingInterval:config:getAsInt("SMB_POLLING_INTERVAL"),
    fileNamePattern:conf.fileNamePattern,  
     secureSocket: {
        basicAuth: {
            username: config:getAsString("SMB_USERNAME"),
            password: password: config:getAsString("SMB_PASSWORD")
        }
    },
    path: "/sambaInFolder"
});
```

6. Implement the ftp client endpoint to do the file processing.

```ballerina
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:SMB,
    host: config:getAsString("SMB_HOST"),
    port: config:getAsInt("SMB_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("SMB_USERNAME"),
            password: config:getAsString("SMB_PASSWORD")
        }
    }
};
```
7. Create a smbClient object.

```ballerina
ftp:Client smbClient = new(ftpConfig);
```

8. Create the file listening resource which will listen to a remote directory on the ftp server and periodically notify the addition of a file with the specified file pattern.

```ballerina
service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {
            var proRes = processFile(untaint v1.path);

             if (proRes == MOVE) {
                // implementation

                string destFilePath = createFolderPath(v1,conf.destFolder);
                error? renameErr = smbClient->rename(v1.path, destFilePath);

            } else if (proRes == DELETE) {
                // implementation
            } else {
               // implementation
            }
        }
    }
```
9. Implement the file processing logic inside the processFile() function.<br/>
This function will return MOVE or DELETE of Operation type based on the functionality we defined in the configs if the file processing is successful or an ERROR if the processing fails.

```ballerina
public function processFile(string sourcePath) returns Operation {

    var getResult = smbClient->get(sourcePath);
    Operation res = ERROR;

    // implementation
    // returns MOVE or DELETE if processing is successful
    // returns ERROR if processing fails

    return  res;
}
```

10. We can have the following functions to generate the file paths where the file needs to be moved after processing or after failure in processing.

```ballerina
public function createFolderPath(ftp:FileInfo v2,string folderPath) returns string {
    string p2 = createPath(v2);
    string path = folderPath + "/" + p2;
    return path;
}

public function createPath(ftp:FileInfo v3) returns string {
    int subString = v3.path.lastIndexOf("/");
    int length = v3.path.length();
    string subPath = v3.path.substring((subString + 1), length);
    return subPath;
}
```

## Invoking the service

When we upload a file with the same file name pattern defined in the configs to the folder defined in the ftp listener instance the ftp listener will invoke, process the file and do the operation defined in the configs (i.e either Move to the defined folder or Delete the processed) if the processing is successful.

