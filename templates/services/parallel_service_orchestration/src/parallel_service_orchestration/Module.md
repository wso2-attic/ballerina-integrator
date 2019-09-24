# Parallel Service Orchestration

Parallel service orchestration is the process of integrating two or more services to automate a particular task or business process where the service orchestrator consumes the resources available in services in a parallel manner. This template demonstrates the implementation of parallel service orchestration using the Ballerina language.

An HTTP listener is used to invoke multiple resources of 2 mock backend services parallelly using the `fork` and `worker` feature in Ballerina language. Their results are accumulated to provide a response to the client invoking the service.

Please use the guide on [Parallel Service Orchestration](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/services/parallel-service-orchestration) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | 
|:---------------------------:|
|  1.0.0                     |

## Running the Template
Execute the following Ballerina command from within the Ballerina project folder to start the HTTP listener service.
```ballerina    
ballerina run <module_name>
```
The following logs confirm that HTTP listener service and mock backend services have started successfully.
``` 
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
[ballerina/http] started HTTP/WS listener 0.0.0.0:9091
[ballerina/http] started HTTP/WS listener 0.0.0.0:9092
```
Invoke the service with the following request. Use an HTTP client like cURL.
```
curl -X GET http://localhost:9090/parallelService
```