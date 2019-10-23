Template for Pass-Through Messaging

# Pass-Through Messaging using Ballerina

This is a template for the [Pass-through Messaging tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/pass-through-messaging/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `pass_through_messaging` template from Ballerina Central.

```
$ ballerina pull wso2/pass_through_messaging
```

Create a new project.

```bash
$ ballerina new pass-through-messaging
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/pass_through_messaging pass_through_messaging
```

This automatically creates pass_through_messaging service for you inside the `src` directory of your project.  

## Testing

Let’s build the module. Navigate to the project root directory and execute the following command.
```
$ ballerina build pass_through_messaging
```

The build command would create an executable .jar file. Now run the .jar file created in the above step using the following command.
```
$ java -jar target/bin/pass_through_messaging.jar
```

