# Routing Requests Based on Message Content

This guide demonstrates how to route a message to a HTTP service based on the content of the message and the invocation URL.

The high level sections of this guide are as follows:

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Deployment](#deployment)
- [Testing](#testing)

## What you'll build
Let's consider a real world scenario where patients use a hospital service. It facilitates reserving appointments on doctors in different catagories at different hospitals registered in the system.

The system is received a message for reservation from the client. The hospital name and the doctor name is extracted from the message payload. The category of service (e.g.: surgery) is extracted from the requested URL.

Then the reservation request is sent to the required hospital service based on the above information. If message is sent successfully, the system will get a response message with the appointment information which would be responded to the client.

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)

- A Text Editor or an IDE
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

- [cURL](https://curl.haxx.se) or any other REST client


## Implementation
> If you want to skip the basics and move directly to the [Testing](#testing) section, you can clone the project from Github and skip the [Implementation](#implementation) instructions.
The following is the code of the service that performs the content based routing on the client request.

**content_based_routing.bal**
```ballerina
import ballerina/http;
import ballerina/log;

// Endpoint URL of the backend service
http:Client locationEP = new("http://localhost:9090");

// Service to reserve appointments
@http:ServiceConfig {
    basePath: "/healthcare"
}
service contentBasedRouting on new http:Listener(9080) {

    // Reserve appointments on the type of "category"
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function CBRResource(http:Caller outboundEP, http:Request req, string category) {

        // Request message payload
        var jsonMsg = req.getJsonPayload();
        if (jsonMsg is json) {
            string hospitalDesc = jsonMsg["hospital"].toString();
            string doctorName = jsonMsg["doctor"].toString();
            string hospitalName = "";

            http:Response|error clientResponse;
            if (hospitalDesc != "") {
                match hospitalDesc {
                    "grand oak community hospital" => hospitalName = "grandoaks";
                    "clemency medical center" => hospitalName = "clemency";
                    "pine valley community hospital" => hospitalName = "pinevalley";
                    _ => respondWithError(outboundEP, "Hospital name is invalid.", "Hospital name is invalid.");
                }
                string sendPath = "/" + hospitalName + "/categories/" + category + "/reserve";

                // Call the backend service related to the hospital
                clientResponse = locationEP -> post(untaint sendPath, untaint jsonMsg);
            } else {
                respondWithError(outboundEP, "JSON Path $hospital cannot be empty.", "Hospital cannot be empty.");
                return;
            }
            if (clientResponse is http:Response) {
                var result = outboundEP->respond(clientResponse);
                handleErrorResponse(result, "Error at the backend");
            } else {
                respondWithError(outboundEP, <string>clientResponse.detail().message, "Backend service does not properly respond");
            }
        } else {
            respondWithError(outboundEP, untaint <string>jsonMsg.detail().message, "Request is not JSON");
        }
    }
}

# Error handle the responses
function handleErrorResponse(http:Response|error? response, string errorMessage) {
    if (response is error) {
        log:printError(errorMessage, err = response);
    }
}

# Respond in error cases
function respondWithError(http:Caller outboundEP, string payload, string failedMessage) {
    http:Response res = new;
    res.statusCode = 500;
    res.setPayload(payload);
    var result = outboundEP->respond(res);
    handleErrorResponse(result, failedMessage);
}
```

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below.

### Deploying locally

To deploy locally, navigate to asynchronous-messaging/guide, and execute the following command.

```
$ ballerina build
```
This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder.
You can run them with the command:

```
$ ballerina run <Exec_Archive_File_Name>
```

### Deploying on Docker

If necessary you can run the service that you developed above as a Docker container.The Ballerina language includes a Ballerina_Docker_Extension, which offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.


## Testing
Follow the steps below to invoke the service.

- Start the `Hospital-Service-2.0.0`.

- Navigate to `routing-requests-based-on-message-content/guide`, and execute the following command to start the service:

```ballerina
   $ ballerina run content_based_routing.bal
```
- Use the request message file `request.json` located in `routing-requests-based-on-message-content/resources` to invoke the service:

**request.json**
```json
{
  "patient": {
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com"
  },
  "doctor": "thomas collins",
  "hospital": "grand oak community hospital",
  "appointment_date": "2025-04-02"
}
```
- Navigate to `routing-requests-based-on-message-content/resources` and send the request message to the service using cURL.
```
curl -v -X POST --data @request.json http://localhost:9080/healthcare/categories/surgery/reserve --header "Content-Type:application/json"
```
#### Output
You will get the following response with the appointment details.

```json
{
    "appointmentNumber": 1,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "fee": 7000.0,
    "confirmed": false,
    "appointmentDate": "2025-04-02"
}
```
`appointmentNumber` would start from `1` and increment for each response by `1`.
