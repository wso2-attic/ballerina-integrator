# Hello World Service

This template demonstrates a simple Hello World Service.

## How to run the template

1. Alter the config file `src/hello_world_service/resources/ballerina.conf` as per the requirement. 

2. Execute the following command to run the service.
```bash
ballerina run --config src/hello_world_service/resources/ballerina.conf hello_world_service
```

3. Invoke the service with the following request. Use an HTTP client like cURL.
```bash
curl http://localhost:9090/hello/sayHello
```