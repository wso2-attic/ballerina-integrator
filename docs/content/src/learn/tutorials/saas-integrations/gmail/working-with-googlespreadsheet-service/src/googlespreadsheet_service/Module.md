Template for Google Spreadsheet Connector Service

# Google Spreadsheet Connector Service 

This is a template for [Google Spreadsheet Connector Service tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/saas-integrations/gmail/googlespreadsheet-service/1.md). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `googlespreadsheet_service` template from Ballerina Central.

```
$ ballerina pull wso2/googlespreadsheet_service
```

Create a new project.

```bash
$ ballerina new working-with-googlespreadsheet-service
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/googlespreadsheet_service googlespreadsheet_service
```

This automatically creates googlespreadsheet_service for you inside the `src` directory of your project.  

## Testing

Add configurations to the `ballerina.conf` file.
   - `ballerina.conf` file can be used to provide external configurations to Ballerina programs.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
   
```
ACCESS_TOKEN="<Acces_token>"
CLIENT_ID="<Client_id">
CLIENT_SECRET="<Client_secret>"
REFRESH_TOKEN="<Refresh_token>"
REFRESH_URL = "<Refresh_URL>"
LISTENER_PORT = Listener_port>
BASE_PATH = "/spreadsheets"

```
Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build googlespreadsheet_service 
```

This creates the executables. Now run the `googlespreadsheet_service.jar` file created in the above step.

```bash
$ java -jar target/bin/googlespreadsheet_service.jar --b7a.config.file=path/to/ballerina.conf/file
```

Now we can see that the service has started on port 9090.
