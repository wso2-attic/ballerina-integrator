# Message Filtering Transformation Template

This template demonstrates an instance where message filtering is used to filter incoming requests based on their 
content.

This template consists of the `filterService`, which will process incoming student data, and check if they have 
qualified from an exam. If a student has not qualified, the service will discard the message. If a student has 
qualified, the student record will be sent to a backend service for persistence. 

## How to run the Template

1. Alter the config file `src/message_filter_service/resources/ballerina.conf` as per the requirement.

2.  Execute following command to run the service.
    ```bash
    ballerina run --config src/message_filter_service/resources/ballerina.conf message_filter_service
    ```

3.  Create a file named request.xml with the following content:
    ```json
    { "name":"Anne",
      "subjects":[{"subject":"Maths","marks": 80},
                  {"subject":"Science","marks":40}]
    }
    ```

4.  Invoke the service with the following request using an HTTP client like cURL.
    ```curl
    curl -X POST -d @request.xml  http://localhost:9090/filterService/FilterMarks  -H "Content-Type: application/json"
    ```