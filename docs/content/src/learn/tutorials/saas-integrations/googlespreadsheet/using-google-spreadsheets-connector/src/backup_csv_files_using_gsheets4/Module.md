Template for Backup CSV using GoogleSpreadsheet

# Google Spreadsheet

This is a template for the [Google Spreadsheet Tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/googlespreadsheet/using-google-spreadsheets-connector/1/).
Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario.

## Using the template

Run the following command to pull the 'googlespreadsheet' template from Ballerina Central.

```bash
$ ballerina pull wso2/backup_csv_files_using_gsheets4
```

Create a new project

```bash
$ ballerina new using-google-spreadsheets-connector
```

Now navigate into the above project directory you create and run the following command to apply the predefined template 
you pulled earlier

```bash
$ ballerina add backup_csv_files_using_gsheets4 -t wso2/backup_csv_files_using_gsheets4
```

This automatically creates backup_csv_files_using_gsheets4 service for you inside the 'src' directory of your projects

## Testing

### 1. Set up credential for accessing Google Spreadsheets
For detailed instructions on obtaining credentials for the Google Spreadsheet can be found [here](https://docs.wso2.com/display/IntegrationCloud/Get+Credentials+for+Google+Spreadsheet).

- Visit [Google API Console Credentials page](https://console.developers.google.com/apis/credentials) and create a new project.

- On the Credentials page, click Create credentials, and then select `OAuth client ID`. Under Application type, select Web application and then give the following information. Note down the client ID and client secret that are created.

- Click the Library link in the left-hand panel, type sheets, and click the Google Sheets API link to open it. Go to [OAuth2 Playground](https://developers.google.com/oauthplayground/#step1&scopes=https%253A//www.googleapis.com/auth/adwords&url=https%253A//&content_type=application/json&http_method=GET&useDefaultOauthCred=checked&oauthEndpointSelect=Google&oauthAuthEndpointValue=https%253A//accounts.google.com/o/oauth2/auth&oauthTokenEndpointValue=https%253A//www.googleapis.com/oauth2/v3/token&includeCredentials=unchecked&accessTokenType=bearer&autoRefreshToken=unchecked&accessType=offline&forceAprovalPrompt=checked&response_type=code), which should pre-populate some key values for you.

- In the Step 1 - Select & authorize APIs section on the left-hand side of the screen, expand Google Sheets API V4, select all the URLs underneath it, and then click Authorize APIs. In the Step 2 - Exchange authorization code for tokens section, note that you now see an authorization code. Click Exchange authorization code for tokens. Note that you see the Refresh token and Access token filled in for you in Step 2 - Exchange authorization code for tokens

### 2. Adding the configuration file
Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. This file should have the following configurations. Add the obtained Google Spreadsheet cofigurations to the file

```
ACCESS_TOKEN="<Google Spreadsheet Access Token>"
CLIENT_ID="<Google Spreadsheet Client Id>"
CLIENT_SECRET="<Google Spreadsheet Client Secret>"
REFRESH_URL="<Refresh URL>"
REFRESH_TOKEN="<Refresh Token>"
``` 

### 3. Running the program
Once you are done with the development, you can deploy the scenario using any of the methods listed below.

```bash
ballerina build backup_csv_files_using_gsheets4
```

This builds a JAR file (.jar) in the target folder. You can run this by using the `java -jar` command.

```bash
java -jar target/bin/backup_csv_files_using_gsheets4.jar
```

You will see that the data stored in the CSV file is sent to the spreadsheet and subsequently read and displayed on the console. 