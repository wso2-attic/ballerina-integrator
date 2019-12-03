Template for Ballerina Gmail Connector.

# Working with Ballerina Gmail Connector

This is a template for the [Using the Gmail Connector tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/gmail/using-the-gmail-connector/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario.

## Using the Template

Run the following command to pull the `gmail_client_application` template from Ballerina Central.

```
$ ballerina pull wso2/gmail_client_application
```

Create a new project.

```bash
$ ballerina new using-the-gmail-connector
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/gmail_client_application gmail_client_application
```

This automatically creates a gmail_client_application for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build gmail_client_application 
```

This creates the executables. Now run the `gmail_client_applicationt.jar` file created in the above step.

```bash
$ java -jar target/bin/gmail_client_application.jar
```

Now we can see that the service has started on port 9090.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```
