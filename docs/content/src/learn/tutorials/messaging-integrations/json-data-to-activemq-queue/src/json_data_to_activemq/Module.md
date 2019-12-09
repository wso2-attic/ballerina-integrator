Template for Sending JSON data to ActiveMQ queue

# Sending JSON data to ActiveMQ queue

This is a template for the [Sending JSON Data to an ActiveMQ Queue tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/messaging-integrations/json-data-to-activemq-queue/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `json_data_to_activemq` template from Ballerina Central.

```
$ ballerina pull wso2/json_data_to_activemq
```

Create a new project.

```bash
$ ballerina new json-data-to-activemq-queue
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add json_data_to_activemq -t wso2/json_data_to_activemq
```

This automatically creates json_data_to_activemq service for you inside the `src` directory of your project.  

## Testing

### Before you begin

Before building the module, we have to copy the necessary ActiveMQ dependencies into the project. There are three jar 
files listed down below. These .jar files can be found in the `lib` folder of the ActiveMQ distribution.

* activemq-client-5.15.5.jar
* geronimo-j2ee-management_1.1_spec-1.0.1.jar
* hawtbuf-1.11.jar

This example uses ActiveMQ version 5.15.5. You can select the relevant jar files according to the ActiveMQ version.

Let's create a folder called `lib` under project root path. Then copy above three jar files into the lib folder.

Next, open the Ballerina.toml file and add the following below `[dependencies]` section. At the build time, ActiveMQ jar 
files will add to the executable jar.

```
[platform]
target = "java8"

  [[platform.libraries]]
  module = "json_data_to_activemq"
  path = "./lib/activemq-client-5.15.5.jar"

  [[platform.libraries]]
  module = "json_data_to_activemq"
  path = "./lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar"

  [[platform.libraries]]
  module = "json_data_to_activemq"
  path = "./lib/hawtbuf-1.11.jar"
```

### Invoking the service

Let’s build the module. While being in the `json-data-to-activemq-queue` directory, execute the following command.

```bash
$ ballerina build json_data_to_activemq
```

The build command would create an executable jar file. Now run the jar file created in the above step.

```bash
$ java -jar target/bin/json_data_to_activemq.jar
```

Now we can see that the service has started on port 8080. 
