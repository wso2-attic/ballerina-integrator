# SMB Listener

This template we'll implement SMB listener which will listen to a remote directory and periodically notify the addition of a file that complies with the specified file pattern.

## How to run the template

1. Alter the config file `src/smb_listener/resources/ballerina.conf` according to your requirement. 

2. Execute the following command in the project directory smb_listener to run the service.
```bash
ballerina run --config src/smb_listener/resources/ballerina.conf smb_listener
```
3. Invoke the service by uploading a file with the same file name pattern defined in the configs to the folder defined in the smb listener instance. Then the file is processed and the operation defined in the configs (i.e either Move to the defined folder or Delete the processed) will be carried out if the processing is successful.

