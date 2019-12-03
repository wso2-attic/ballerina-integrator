Template for Message Store Reliable Delivery

# Reliable Delivery 

This is a template for the [Reliable Delivery Tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/messaging-integrations/reliable-delivery/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following commands to pull the `message_store` and `message_processor` templates from Ballerina Central.

```
$ ballerina pull wso2/message_store
$ ballerina pull wso2/message_processor
```

Create a new project.

```bash
$ ballerina new reliable-delivery
```

Now navigate into the above module directory you created and run the following commands to apply the predefined templates you pulled earlier.

```bash
$ ballerina add -t wso2/message_store message_store
$ ballerina add -t wso2/message_processor message_processor
```

This automatically creates reliable delivery service for you inside the `src` directory of your project.  

## Testing

First, start the message broker you installed previously. If you are using Active MQ, you can navigate to `<ACTIVE_MQ_HOME>/bin` 
and start the broker by running the command below.

```bash
$ ./activemq console
```

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build -a 
```

This creates the executables.

Now run the two jar files created in the earlier step to start the store and processing services.

```bash
$ java -jar target/bin/message_store.jar
```

```bash
$ java -jar target/bin/message_processor.jar
```

Send a request using curl to the message storing service to trigger a message processing request.

```bash
$ curl -i -X POST http://localhost:8080/orders/new-order -H "Content-Type: application/json" --data-binary "@/resources/input.json"
```

You will see the following response in a successful invocation. 

```bash
$ INFO  [wso2/message_processor] - Stock order persisted sucessfully. 
```
