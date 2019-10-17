Template for REST to SOAP Conversion

# REST to SOAP 

This is a template for the [REST to SOAP tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/exposing-soap-service/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `stockquote_service` template from Ballerina Central.

```
$ ballerina pull wso2/stockquote_service
```

Create a new project.

```bash
$ ballerina new exposing-a-soap-service
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/stockquote_service stockquote_service
```

This automatically creates restful_service for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build stockquote_service 
```

This creates the executables. Now run the `restful_service.jar` file created in the above step.

```bash
$ java -jar target/bin/stockquote_service.jar
```

Now we can see that two services have started on ports 9000 and 9090. 