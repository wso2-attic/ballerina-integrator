Template for Service Orchestration

# Service Orchestration 

This is a template for the [Service Orchestration](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/service-orchestration/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `service_orchestration` template from Ballerina Central.

```
$ ballerina pull wso2/service_orchestration
```

Create a new project.

```bash
$ ballerina new service-orchestration
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add service_orchestration -t wso2/service_orchestration
```

This automatically creates service_orchestration for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build service_orchestration
```

This creates the executables. Now run the `service_orchestration.jar` file created in the above step.

```bash
$ java -jar target/bin/service_orchestration.jar
```

Now we can see three service have started on ports 8081, 8082, and 9090.