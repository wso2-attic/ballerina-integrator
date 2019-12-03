Template for Content-Based Routing using Ballerina

# Content-Based Routing using Ballerina

This is a template for the [Content-based Routing tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/content-based-routing/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `content_based_routing` template from Ballerina Central.

```
$ ballerina pull wso2/content_based_routing
```

Create a new project.

```bash
$ ballerina new content-based-routing
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/content_based_routing content_based_routing
```

This automatically creates content_based_routing service for you inside the `src` directory of your project.  

## Testing

Let’s build the module. While being in the content-based-routing directory, execute the following command.

```bash
$ ballerina build content_based_routing
```

This would create the executables. Now run the `content_based_routing.jar` file created in the above step.

```bash
$ java -jar target/bin/content_based_routing.jar
```

Now we can see that three service have started on ports 8081, 8082, and 9090.
