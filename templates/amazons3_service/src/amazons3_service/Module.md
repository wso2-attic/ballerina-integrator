# Amazon S3 Connector Service

This template demonstrates on how to use Amazon S3 connector

## How to run the template

1. Alter the config file `src/amazons3_service/resources/ballerina.conf` as per the requirement. 

2. Execute the following command to run the service.
    ```bash
    ballerina run --config src/amazons3_service/resources/ballerina.conf amazons3_service
    ```
3. Invoke the service with the following curl requests.
    1. Create a new bucket
       ```
       curl -v -X POST http://localhost:9090/amazons3/firstbalbucket
       ```
    2. List buckets
       ```
       curl -X GET http://localhost:9090/amazons3
       ```
    3. Create object
    
       Create a file called content.json with following JSON content:
       ```json
       {
           "name": "John Doe",
           "dob": "1940-03-19",
           "ssn": "234-23-525",
           "address": "California",
           "phone": "8770586755",
           "email": "johndoe@gmail.com",
           "doctor": "thomas collins",
           "hospital": "grand oak community hospital",
           "cardNo": "7844481124110331",
           "appointment_date": "2025-04-02"
       }
       ```
       Invoke following curl request
       ```
       curl -v -X POST --data @content.json http://localhost:9090/amazons3/firstbalbucket/firstObject.json --header "Content-Type:application/json"
       ```
    4. List objects
       ```
       curl -X GET http://localhost:9090/amazons3/firstbalbucket
       ```
    5. Get object
       ```
       curl -v -X GET http://localhost:9090/amazons3/firstbalbucket/firstObject.json?responseContentType=application/json
       ```
    6. Delete object
       ```
       curl -v -X DELETE http://localhost:9090/amazons3/firstbalbucket/firstObject.json
       ```
    7. Delete bucket
       ```
       curl -v -X DELETE http://localhost:9090/amazons3/firstbalbucket
       ```