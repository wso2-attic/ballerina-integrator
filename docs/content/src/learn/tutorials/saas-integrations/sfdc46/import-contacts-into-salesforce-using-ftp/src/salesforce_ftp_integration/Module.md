Template for Integrating Salesforce with FTP

# Integrating Salesforce with FTP 

This is a template for the [Import Contacts into Salesforce Using FTP tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/sfdc46/import-contacts-into-salesforce-using-ftp/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `salesforce_ftp_integration` template from Ballerina Central.

```
$ ballerina pull wso2/salesforce_ftp_integration
```

Create a new project.

```bash
$ ballerina new import-contacts-into-salesforce-using-ftp
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add salesforce_ftp_integration -t wso2/salesforce_ftp_integration
```

This automatically creates salesforce_ftp_integration for you inside the `src` directory of your project.  

## Testing

### 1. Set up remote FTP server and obtain the following credentials:

- FTP Host
- FTP Port
- FTP Username
- FTP Password
- Path in the FTP server to add CSV files

Add the `src/salesforce_ftp_integration/resources/contacts.csv` file to the FTP path you mentioned above.

### 2. Add project configurations file

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

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build salesforce_ftp_integration
```

This creates the executables. Now run the `salesforce_ftp_integration.jar` file created in the above step.

```bash
$ java -jar target/bin/salesforce_ftp_integration.jar
```

You will see the following log after successfully importing contacts to Salesforce.

```
2019-09-26 19:14:09,916 INFO  [wso2/salesforce_ftp_integration] - CSV file added to the FTP location: /home/ftp-user/sfdc/contacts.csv
2019-09-26 19:14:13,855 INFO  [wso2/salesforce_ftp_integration] - Imported contacts successfully!
```
