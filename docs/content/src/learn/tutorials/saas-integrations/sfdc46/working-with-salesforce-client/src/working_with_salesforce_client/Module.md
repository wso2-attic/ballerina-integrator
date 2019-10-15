Template for Working with Salesforce client

# Working with Salesforce client 

This template refers to the tutorial described in [Working with Salesforce client](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/sfdc46/working-with-salesforce-client/1/). Please refer it for more details on what you are going to build here and the prerequisites for building the module .

#### Executing the Template

- Run the following command to pull the ```working_with_salesforce_client``` template from the Ballerina Central.

```
$ ballerina pull wso2/working_with_salesforce_client
```

- Create a new project.

```bash
$ ballerina new working-with-salesforce-client
```

- Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/working_with_salesforce_client working_with_salesforce_client
```

This automatically creates a working_with_salesforce_client for you inside the `src` directory of your project .  

### Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build working_with_salesforce_client 
```

This creates the executables. Now run the `working_with_salesforce_client.jar` file created in the above step.

```bash
$ java -jar target/bin/working_with_salesforce_client.jar
```

You will see service the following log.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```

#### Test createAccount resource

Create a file called `account.json` with following JSON content:
```json
{
    "Name": "Levi Straus & Co",
    "BillingCity": "California",
    "Website": "www.levis-clothing.com",
    "Contacts": [
        {
            "FirstName": "Sam",
            "LastName": "Pattinson",
            "Title": "Senior Manager",
            "Department": "Sales",
            "Email": "sampat@levis.com"
        },
        {
            "FirstName": "John",
            "LastName": "Auguero",
            "Title": "Assistant Manager",
            "Department": "Sales",
            "Email": "auguero@levis.com"
        }
    ],
    "Opportunities": [
        {
            "Name": "Mens 501 Summer Collection",
            "Amount": 235000,
            "CloseDate": "2019-05-21",
            "Probability": 100,
            "StageName": "Qualification"
        },
        {
            "Name": "Mens 510 Summer Collection",
            "Amount": 330000,
            "CloseDate": "2019-05-27",
            "Probability": 90,
            "StageName": "Qualification"
        }
    ]
}
```

Invoke the following curl request to create a new Account and related Contacts & Opportunities using the created 
JSON file.
```bash
curl -X POST -H "Content-Type: application/json" -d @account.json http://localhost:9090/salesforce/account
```

You will see the following response.
```json
{
  "accountId":"0012v00002Xaac8AAB",
  "contacts":[
    "0032v00002y28KQAAY", 
    "0032v00002y28KVAAY"
    ], 
  "opportunities":[
    "0062v00001H9RXiAAN", 
    "0062v00001H9RXnAAN"
    ]
}
```

#### Test executeQuery resource

Here we are going to query and retrieve IDs and Names of all the opportunities related to the newly added account.
We can achieve this by running following SOQL query.
```sql
SELECT Id, Name FROM Opportunity WHERE AccountId = '<ACCOUNT_ID_OF_THE_CREATED_ACCOUNT>'
```

Invoke the following curl request to execute the query.
```bash
curl -X POST -H "Content-Type: text/plain" -d "SELECT Id, Name FROM Opportunity WHERE AccountId = '<ACCOUNT_ID_OF_THE_CREATED_ACCOUNT>'" http://localhost:9090/salesforce/query
```

You will see the following response.
```json
{
    "totalSize": 3,
    "done": true,
    "records": [
        {
            "attributes": {
                "type": "Opportunity",
                "url": "/services/data/v46.0/sobjects/Opportunity/0062v00001ErIvIAAV"
            },
            "Id": "0062v00001ErIvIAAV",
            "Name": "Mens 510 Summer Collection"
        },
        {
            "attributes": {
                "type": "Opportunity",
                "url": "/services/data/v46.0/sobjects/Opportunity/0062v00001ErIvDAAV"
            },
            "Id": "0062v00001ErIvDAAV",
            "Name": "Mens 501 Summer Collection"
        }
    ]
}
```
