# Import Contacts Into Salesforce using FTP connector

## About

Ballerina is an open-source programming language that supports developers to integrate their system easily with the 
support of connectors. In this guide, we are mainly focusing on importing CSV file having contacts into Salesforce
using FTP connector. 

The `wso2/sfdc46` module allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and 
describe SObjects and organizational data through the Salesforce REST API. Also it supports insert, upsert, update, 
query and delete operations for CSV, JSON and XML data types which provides in Salesforce bulk API. It handles OAuth 
2.0 authentication.

The `wso2/ftp` module provides an FTP client and an FTP server listener implementation to facilitate an FTP connection 
to a remote location.

You can find other integrations modules from [wso2-ballerina](https://github.com/wso2-ballerina) Github organization.

## What you'll build

This application listens to a remote FTP location and when the CSV file appears (this CSV file contains contacts that 
should be added to salesforce) it will fetch the CSV file content and insert all the contacts in the CSV file into 
Salesforce using `salesforceBulkClient` as a single batch. Then it will get the insertion result using 
`salesforceBulkClient` and if the operation is successful, a success message is logged.

![import contacts to sfdc using ftp](../../../../../assets/img/import-contacts-into-salesforce-using-ftp.jpg)

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

A Ballerina project needs to be created for the integration use case explained above. Please follow the steps given 
below to create the project and modules. You can learn about the Ballerina project and modules in this 
[guide](https://ei.docs.wso2.com/en/latest/ballerina-integrator/develop/using-modules/#creating-a-project).

#### 1. Create a new project.

```bash
$ ballerina new import-contacts-into-salesforce-using-ftp
```

#### 2. Create a module.

```bash
$ ballerina add guide
```

The project structure is created as indicated below.

```
import-contacts-into-salesforce-using-ftp
    ├── Ballerina.toml
    └── src
        └── guide
            ├── Module.md
            ├── main.bal
            ├── resources
            └── tests
                └── resources
```

#### 3. Set up credentials for accessing Salesforce
   
- Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.

- Create a connected app and obtain the following credentials: 
    - Base URL (Endpoint)
    - Access Token
    - Client ID
    - Client Secret
    - Refresh Token
    - Refresh Token URL

- **Note**: When you are setting up the connected app, select the following scopes under **Selected OAuth Scopes**:
    - Access and manage your data (api)
    - Perform requests on your behalf at any time (refresh_token, offline_access)
    - Provide access to your data via the Web (web)

- Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
obtaining OAuth2 credentials, see the 
[Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

#### 4. Set up remote FTP server

Set up remote FTP server and obtain the following credentials:

- FTP Host
- FTP Port
- FTP Username
- FTP Password
- Path in the FTP server to add CSV files

Add the `src/guide/resources/contacts.csv` file to the FTP path you mentioned above.

#### 5. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the obtained Salesforce configurations and FTP configurations
to the file.

```
SF_BASE_URL="<Salesforce base url (eg: https://ap15.salesforce.com)>"
SF_ACCESS_TOKEN="<Salesforce access token>"
SF_CLIENT_ID="<Salesforce client ID>"
SF_CLIENT_SECRET="<Salesforce client secret>"
SF_REFRESH_URL="<Salesforce refresh url (eg: https://login.salesforce.com/services/oauth2/token)>"
SF_REFRESH_TOKEN="<Salesforce refresh token>"
SF_NO_OF_RETRIES=<No of retries for getting inserion results (eg: 10)>
FTP_HOST="<FTP host IP (eg: 192.168.112.8)>"
FTP_PORT=<FTP host port (eg: 21)>
FTP_USERNAME="<FTP username>"
FTP_PASSWORD="<FTP password>"
FTP_PATH="<Path in the FTP server you added conatats.csv (eg: /home/ftp-user/sfdc)>"
FTP_POLLING_INTERVAL=<FTP listner polling interval (eg: 600000)>
```

#### 6. Write the integration

Open the project with VS Code. The integration implementation is written in the `src/guide/main.bal` file.

<!-- INCLUDE_CODE: src/guide/main.bal -->

Here the `ftpServerConnector` service is running on `remoteServer`, which listens to the configured FTP server 
location. When a CSV file is added to the FTP server, the file content will be retrieved and inserted into the 
Salesforce using `sfBulkClient`.

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build guide
```

This creates the executables. Now run the `guide.jar` file created in the above step.

```bash
$ java -jar target/bin/guide.jar
```

You will see the following log after successfully importing contacts to Salesforce.

```
2019-09-26 19:14:09,916 INFO  [wso2/guide] - CSV file added to the FTP location: /home/ftp-user/sfdc/contacts.csv 
2019-09-26 19:14:13,855 INFO  [wso2/guide] - Imported contacts successfully!
```
