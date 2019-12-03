Template for Service Orchestration

# Service Orchestration 

This is a template for the [Service Orchestration](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/service-orchestration/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `appointment_service` template from Ballerina Central.

```
$ ballerina pull wso2/appointment_service
```

Create a new project.

```bash
$ ballerina new service-orchestration
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/appointment_service appointment_service
```

This automatically creates appointment_service for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build appointment_service 
```

This creates the executables. Now run the `appointment_service.jar` file created in the above step.

```bash
$ java -jar target/bin/appointment_service.jar
```

Now we can see three service have started on ports 8081, 8082, and 9090.    