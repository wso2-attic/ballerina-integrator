# Google spreadsheet and Salesforce API Integration

This template demonstrates some of the capabilities of Google spreadsheet and Salesforce modules.

`salesforceService` HTTP service will be created with this template. salesforceService has a 3 resources called 
`addAccount`, `addContacts` and `deleteContacts`. `addAccount` resource creates a Account in Salesforce using a given 
JSON. `addContacts` resource creates contacts in Salesforce for a given Account using Google spreadsheet data. Here
we are going to add contacts in 
[this spreadsheet](https://docs.google.com/spreadsheets/d/1nROELRHZ9JadnvIBizBfnx0FASo2tg7r-gRP1ribYNY/edit?usp=sharing) 
to Salesforce. `deleteContacts` resource deletes Salesforce contacts for a given Account.

## How to run the template

1. Alter the config file `src/gsheets_salesforce_integration/resources/ballerina.conf` as per the requirement.

2.  Execute following command to run the service.
    ```bash
    ballerina run gsheets_salesforce_integration --config src/gsheets_salesforce_integration/resources/ballerina.conf
    ```
    Following log confirms service started successfully.
    ```
    [ballerina/http] started HTTP/WS listener 0.0.0.0:9092
    ```

3.  Create a file named account.json with the following content:
    ```json
    {
        "Name": "WSO2 learn Inc",
        "BillingCity": "New York"
    }
    ```

4.  Invoke the service with the following request to create the Salesforce account. Use an HTTP client like cURL.
    ```curl
    curl -X POST -d @account.json  http://localhost:9092/salesforce/account  -H "Content-Type: application/json"
    ```

5. Above request will respond the created Account ID. You need this Account ID to invoke next 2 resources.

6. Create a file named spreadsheet.json with the following content:
    ```json
    {
        "spreadsheetId": "1nROELRHZ9JadnvIBizBfnx0FASo2tg7r-gRP1ribYNY",
        "sheetName": "contacts",
        "noOfRows": 11
    }
    ```

7. Invoke the service with the following request to insert contacts to the Salesforce. Use an HTTP client like cURL.
   Replace <ACCOUNT_ID> with the Account ID you obtained.
    ```curl
    curl -X POST -d @spreadsheet.json  http://localhost:9092/salesforce/contacts/<ACCOUNT_ID> -H "Content-Type: application/json"
    ```
8. Invoke the service with the following request to delete contacts added to the Salesforce. Use an HTTP client like 
   cURL. Replace <ACCOUNT_ID> with the Account ID you obtained.
    ```curl
    curl -X DELETE  http://localhost:9092/salesforce/contacts/<ACCOUNT_ID>
    ```