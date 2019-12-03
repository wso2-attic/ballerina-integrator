Template for Backend for Frontend

# Backend for Frontend

This is a template for the [Backend for Frontend tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/backend-for-frontend/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `healthcare_service` template from Ballerina Central.

```
$ ballerina pull wso2/healthcare_management_service
```

Create a new project.

```bash
$ ballerina new backend-for-frontend
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/healthcare_management_service healthcare_management_service
```

This automatically creates healthcare_management_service for you inside the `src` directory of your project.  

## Testing

Let’s build the module. Navigate to the project directory and execute the following command.

```bash
$ ballerina build healthcare_management_service
```

The build command would create an executable .jar file. Now run the .jar file created in the above
step.

```bash
$ java -jar target/bin/healthcare_management_service.jar
```

Now we can see that six services have started on ports 9090, 9091, 9092, 9093, 9094, and 9095. 
