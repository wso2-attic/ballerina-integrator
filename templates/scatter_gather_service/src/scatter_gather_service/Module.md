# Scatter-Gather Service

This template demonstrates the scatter-gather enterprise integration pattern where we call multiple backends, aggregated the responses from all the backends and repond then to the client as a single response.

## How to run the template

1. Alter the config file `src/scatter_gather_service/resources/ballerina.conf` as per the requirement. 

2. Execute the following command in the project directory scatter_gather_service to run the service.
```bash
ballerina run --config src/scatter_gather_service/resources/ballerina.conf scatter_gather_service
```
3. Create a file named request.json with the following content:
```json
{"test":"data"}```

4. Invoke the service with the following request. Use an HTTP client like cURL.
```bash
curl http://localhost:9090/endpoints/call -H 'Content-Type:application/json' -d @request.json
```