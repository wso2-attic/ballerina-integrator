# Google spreadsheet and Salesforce API Integration

This template demonstrates some of the capabilities of Google spreadsheet and Salesforce modules.

`salesforceService` HTTP service will be created with this template. salesforceService has a 3 resources called 
`addAccount`, `addContacts` and `deleteContacts`. `addAccount` resource creates a Account in Salesforce using a given 
JSON. `addContacts` resource creates contacts in Salesforce for a given Account using Google spreadsheet data. Here
we are going to add contacts in 
[this spreadsheet](https://docs.google.com/spreadsheets/d/1nROELRHZ9JadnvIBizBfnx0FASo2tg7r-gRP1ribYNY/edit?usp=sharing) 
to Salesforce. `deleteContacts` resource deletes Salesforce contacts for a given Account.

## How to run the template

1. Login to your google account and create a spreadsheet. Then import the `contacts.csv` file located in
   `src/gsheets_salesforce_integration/resources` directory.

2. Obtaining tokens for Salesforce.
   - Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
   - Create a connected app and obtain the following credentials: 
        - Base URL (Endpoint)
        - Access Token
        - Client ID
        - Client Secret
        - Refresh Token
        - Refresh Token URL

        Note:- When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

        - Access and manage your data (api)
        - Perform requests on your behalf at any time (refresh_token, offline_access)
        - Provide access to your data via the Web (web)
    - Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

3. Obtaining tokens from google spreadsheet.
    - Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the 
wizard to create a new project.
    - Go to **Credentials -> OAuth Consent Screen**, enter a product name to be shown to users, and click **Save**.
    - On the **Credentials** tab, click **Create Credentials** and select **OAuth Client ID**.
    - Select an application type, enter a name for the application, and specify a redirect URI 
(enter https://developers.google.com/oauthplayground if you want to use 
[OAuth 2.0 Playground](https://developers.google.com/oauthplayground) to receive the Authorization Code and obtain the 
Access Token and Refresh Token).
    - Click **Create**. Your Client ID and Client Secret will appear.
    - In a separate browser window or tab, visit [OAuth 2.0 Playground](https://developers.google.com/oauthplayground). 
Click on the `OAuth 2.0 Configuration` icon in the top right corner and click on `Use your own OAuth credentials` and 
provide your `OAuth Client ID` and `OAuth Client Secret`.
    - Select the required Gmail API scopes from the list of API's, and then click **Authorize APIs**.
    - When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh 
token and access token.

4. Alter the config file `src/gsheets_salesforce_integration/resources/ballerina.conf` by adding the generated tokens.

5. Execute following command to build the project.
    ```bash
    ballerina build gsheets_salesforce_integration --b7a.config.file=src/gsheets_salesforce_integration/resources/ballerina.conf
    ```
    Then run the created JAR file using following command.
    ```bash
    java -jar target/bin/gsheets_salesforce_integration.jar --b7a.config.file=src/gsheets_salesforce_integration/resources/ballerina.conf
    ```
    Following log confirms service started successfully.
    ```
    [ballerina/http] started HTTP/WS listener 0.0.0.0:9092
    ```

6. Create a file named account.json with the following content:
    ```json
    {
        "Name": "WSO2 learn Inc",
        "BillingCity": "New York"
    }
    ```

7. Invoke the service with the following request to create the Salesforce account. Use an HTTP client like cURL.
    ```curl
    curl -X POST -d @account.json  http://localhost:9092/salesforce/account  -H "Content-Type: application/json"
    ```

8. Above request will respond the created Account ID. You need this Account ID to invoke next 2 resources.

9.  Create a file named spreadsheet.json with the following content:
    ```json
    {
        "spreadsheetId": "1nROELRHZ9JadnvIBizBfnx0FASo2tg7r-gRP1ribYNY",
        "sheetName": "contacts",
        "noOfRows": 11
    }
    ```

10.  Invoke the service with the following request to insert contacts to the Salesforce. Use an HTTP client like cURL.
   Replace <ACCOUNT_ID> with the Account ID you obtained.
    ```curl
    curl -X POST -d @spreadsheet.json  http://localhost:9092/salesforce/contacts/<ACCOUNT_ID> -H "Content-Type: application/json"
    ```
11. Invoke the service with the following request to delete contacts added to the Salesforce. Use an HTTP client like 
   cURL. Replace <ACCOUNT_ID> with the Account ID you obtained.
    ```curl
    curl -X DELETE  http://localhost:9092/salesforce/contacts/<ACCOUNT_ID>
    ```
