# XML to JSON Transformation Template

This template demonstrates some of the message transformation capabilities.

`scienceLabService` HTTP service will be created with this template. scienceLabService has a resource called `addUser`. 
This `addUser` resource constructs a JSON payload after recieving the requset. The actual backend requires a JSON 
message. But the received request is in XML format. Hence `addUser` resource logic transforms XML into JSON mapping 
the necessary elements from the request payload. The endpoint returns a JSON message back to the `scienceLabService` as 
the response. The JSON response get converted to XML and responds back to the client. 

## How to run the template

1.  Execute following command to run the service.
    ```bash
    ballerina run xml_to_json
    ```
    Following log confirms service started successfully.

2.  Create a file named request.xml with the following content:
    ```xml
    <user>
        <name>Sam</name>
        <job>Scientist</job>
    </user>
    ```

3.  Invoke the service with the following request. Use an HTTP client like cURL.
    ```curl
    curl -X POST -d @request.xml  http://localhost:9092/laboratory/user  -H "Content-Type: text/xml"
    ```
