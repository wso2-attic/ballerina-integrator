# SMB Listener

In this template we will implement an SMB listener which will listen to a remote directory and periodically notify the 
addition and deletion of files that comply with the specified file pattern.

## How to run the template

1. Alter the config file `src/<module_name>/resources/ballerina.conf` according to your requirement. 

2. Execute the following command in the project directory `<project_name>` to run the service.
```bash
ballerina run <module_name> --b7a.config.file=src/<module_name>/resources/ballerina.conf
```
3. Invoke the service by uploading a file which has the file name pattern defined in the config, to the folder defined 
in the SMB Listener instance. Then the file is processed and added to the list along with its details. Invoke the 
delete operation by removing a file on the server, which will in turn delete the file entry from the list.

