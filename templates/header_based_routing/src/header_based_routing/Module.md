# Header Based Routing Service

This template demonstrates an instance where a Header based router is used to route requests to different endpoints 
based on the header of each request. 

This template consists of the `calculatorService`, which handles requests to perform arithmetic operations on two 
integers. The service will read each request and route the request according to the arithmetic operation mentioned 
in the request header. The `arithmeticService` which consists of endpoints for the different arithmetic operations, 
will receive the requests and perform the mathematical operations as required. 

## How to run the Template

1. Alter the config file `src/header_based_routing/resources/ballerina.conf` as per the requirement.

2.  Execute following command to run the service.
    ```bash
    ballerina run --config src/header_based_routing/resources/ballerina.conf header_based_routing
    ```

3.  Create a file named request.xml with the following content:
    ```json
    { 
      "valueOne": 40,
      "valueTwo": 50
    }
    ```

4.  Invoke the service with the following request using an HTTP client like cURL.
    ```curl
    curl -X POST -d @request.xml  http://localhost:9090/calculatorService/calculate  -H "Content-Type: application/json"
    -H  "operation: add"
    ```
 