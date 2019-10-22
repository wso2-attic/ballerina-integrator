Template for Working with Salesforce client

# Working with Salesforce Client

This is a template for the the tutorial described in [Working With Salesforce Client tutorial ](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/saas-integrations/sfdc46/working-with-salesforce-client/1/). Please refer it for more details on what you are going to build here. This template provides a starting point for your scenario.

## Using the Template

Run the following command to pull the `working_with_salesforce_client` template from Ballerina Central.

```
$ ballerina pull wso2/working_with_salesforce_client
```

Create a new project.

```bash
$ ballerina new working-with-salesforce-client
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/working_with_salesforce_client working_with_salesforce_client
```

This automatically creates a working_with_salesforce_client for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build working_with_salesforce_client 
```

This creates the executables. Now run the `working_with_salesforce_client.jar` file created in the above step.

```bash
$ java -jar target/bin/working_with_salesforce_client.jar
```

You will see the following service log.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```
