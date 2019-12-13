Template for Messaging with Kafka

# Messaging with Kakfa

This is a template for the [Messaging with Kafka Tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/messaging-integrations/messaging-with-kafka/1/).
Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `messaging-with-kafka` template from Ballerina Central.

```bash
$ ballerina pull wso2/product_management_system
```

Create a new project

```bash
$ ballerina new messaging_with_kafka
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier

```bash
$ ballerina add product_management_system -t wso2/product_management_system
```

This automatically creates messaging_with_kafka service for you inside the 'src' directory of you project.

## Testing
Lets build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build product_management_system
```

We can run the module by executing the following command

```bash
$ java -jar target/bin/product_management_system.jar
```

