# Sending JSON data to ActiveMQ queue

## About 
Ballerina is an open-source programming language that supports developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on connecting to a ActiveMQ broker with the JMS connector. You can find other integrations modules from the [wso2-ballerina](https://github.com/wso2-ballerina) Github repository.

The JMS connector created with a minimum deviation of JMS API for developers who are working with integrates messaging systems. It supports creating consumer, producer as well as listeners. You can find out more about JMS connector from [here](https://github.com/wso2-ballerina/module-jms).

## What you'll build
Ballerina has first-class support for HTTP and implementing an HTTP service is straightforward. The caller will send a JSON payload that consists of a sales order. The HTTP service reads the payload as text. Then with the support of JMS connector, a JMS text message is built and sent to ActiveMQ.

## Prerequisites
- [Java](https://www.oracle.com/technetwork/java/index.html)
- A Text Editor or an IDE
- Link to download Ballerina Integrator

## Implementation
The ballerina project should create for the integration use case explained above. Please follow the steps given below. You can learn about the ballerina project and module in this link.

1. Create a project.
```bash
$ ballerina new sending-json-data-to-a-jms-queue
```
Change directory to the sending-json-data-to-a-jms-queue.

2. Add a module
```bash
$ ballerina add jsontojms
```

The project structure should look like below.
```shell
sending-json-data-to-a-jms-queue
├── Ballerina.toml
└── src
    └── jsontojms
        ├── main.bal
        ├── Module.md
        ├── resources
        └── tests
            └── resources
```

3. Write the integration
You can open the project with VSCode. The integration implemention going to write in the `main.bal` file. 

<!-- INCLUDE_CODE: src/jsontojms/main.bal -->

Same as JMS API, create `jms:Connection` then `jms:Session` and finally create `jms:Destination`, `jms:MessageProducer`. In the HTTP resource, build `jms:TextMessage` getting the payload as a `string`. Next, send the message to the sales queue in the ActiveMQ. Once message send, verify the return result is an error. If it is an error, build `http:Response` as JSON payload. If it is a success, do the same. As the last step, respond to the caller with build `http:Response`.

## Run the integration
Before building the module, we have to copy the necessary ActiveMQ dependencies into the project. There are three jar files listed down below.

* activemq-client-5.15.5.jar
* geronimo-j2ee-management_1.1_spec-1.0.1.jar
* hawtbuf-1.11.jar

This example uses ActiveMQ version 5.15.5. You can select the relevant jar files according to the ActiveMQ version.

Let's create a folder called `lib` under project root path. Then copy above three jar files into the lib folder.

```shell
.
├── Ballerina.toml
├── lib
│   ├── activemq-client-5.15.5.jar
│   ├── geronimo-j2ee-management_1.1_spec-1.0.1.jar
│   └── hawtbuf-1.11.jar
└── src
    └── jsontojms
        ├── main.bal
        ├── Module.md
        ├── resources
        └── tests
            └── resources
```

Next, open the Ballerina.toml file and add the following below `[dependencies]` section. At the build time, ActiveMQ jar files will add to the executable jar.

```
[platform]
target = "java8"

  [[platform.libraries]]
  module = "jsontojmsflow"
  path = "./lib/activemq-client-5.15.5.jar"

  [[platform.libraries]]
  module = "jsontojmsflow"
  path = "./lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar"

  [[platform.libraries]]
  module = "jsontojmsflow"
  path = "./lib/hawtbuf-1.11.jar"
```

Let’s build the module. While being in the sending-json-data-to-a-jms-queue directory, execute the following command.

```bash
$ ballerina build jsontojms
```

The build command would create an executable jar file. Now run the jar file created in the above step.

```bash
$ java -jar target/bin/jsontojms.jar
```

Now we can see that the service has started on port 8080. Let’s access this service by executing the following curl command. Make sure to start the ActiveMQ server before running the service. Otherwise, it will throw an error.

```bash
$ curl -H "application/json" \ 
-d '{"itemCode":"SP1084", "itemName":"Fog Light", "Amount":1000.0, "description":"Car Fog Light", "qty":1, "warehouse":"Colombo"}'.json \ 
http://localhost:8080/sales/orders
```

You will see the following response in a successful invocation. Also, the published message should be able to view in the sales queue when you log into the ActiveMQ web console. 

```json
{"Message": "Order sent for processing."}
```
