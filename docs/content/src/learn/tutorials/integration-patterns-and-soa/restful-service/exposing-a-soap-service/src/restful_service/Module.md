Template for RESTful Service 

# RESTful Service 

This is a template for the the tutorial described in [RESTful Service](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/exposing-soap-service/1/). Please refer it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `restful_service` template from Ballerina Central.

```
$ ballerina pull wso2/restful_service
```

Create a new project.

```bash
$ ballerina new exposing-a-soap-service
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/restful_service restful_service
```

This automatically creates restful_service for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build restful_service 
```

This creates the executables. Now run the `restful_service.jar` file created in the above step.

```bash
$ java -jar target/bin/restful_service.jar
```

You will see the following service log.

```
   Initiating service(s) in 'target/restful_service.balx'
   [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```
