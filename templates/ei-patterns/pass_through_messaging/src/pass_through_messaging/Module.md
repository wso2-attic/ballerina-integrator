# Pass Through Messaging

There are different ways of messaging methods in SOA (Service Oriented Architecture). Pass Through Messaging is used when a message is to be routed without processing/inspecting the message payload. This saves processing time and power, and is more efficient when compared to other messaging types. This template demonstrates a simple pass through messaging scenario.

Please use the guide on [Pass Through Messaging](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/integration-patterns/pass-through-messaging) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Running the Template
Execute the following Ballerina command from within the Ballerina project folder to start the HTTP listener service.
```ballerina    
ballerina run <module_name>
```
The following logs confirm that HTTP listener service and mock backend service have started successfully.
``` 
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
[ballerina/http] started HTTP/WS listener 0.0.0.0:9080
```
Invoke the service with the following request. Use an HTTP client like cURL.
```
curl -X GET http://localhost:9090/service-a
```
