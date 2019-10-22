Template for Service Composition using Ballerina

# Service Composition using Ballerina

This is a template for the [Service Composition tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/service-composition/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `service_composition` template from Ballerina Central.

```
$ ballerina pull wso2/service_composition
```

Create a new project.

```bash
$ ballerina new service-composition
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/service_composition service_composition
```

This automatically creates service_composition service for you inside the `src` directory of your project.  

## Testing

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build service_composition
```

This creates the executables. Now run the `service_composition.jar` file created in the above step. 
```bash
$ java -jar target/bin/service_composition.jar
```

- You can see the travel agency service and related backend services are up and running. The successful startup of services will display the following output.
```
[ballerina/http] started HTTP/WS listener 0.0.0.0:9091
[ballerina/http] started HTTP/WS listener 0.0.0.0:9092
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```
This starts the `Airline Reservation`, `Hotel Reservation`, and `Travel Agency` services on ports 9091, 9092, and 9090 respectively.
