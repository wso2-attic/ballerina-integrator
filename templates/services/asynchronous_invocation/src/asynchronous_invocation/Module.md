# Asynchronous Invocation

Asynchronous invocations or the asynchronous pattern is a design pattern in which the call site is not blocked while waiting for the code invoked to finish. Instead, the calling thread can use the result when the reply arrives. This template demonstrates web services with asynchronous RESTful calls.

An HTTP listener is created, using which 3 mock backend endpoints are invoked asynchronously. Their results are accumulated to provide a response to the client invoking the service.

Please use the guide on [Asynchronous Invocation](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/services/asynchronous-invocation) for a more detailed explanation.

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
curl -X GET http://localhost:9090/asyncInvocation
```
