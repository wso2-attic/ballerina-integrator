# Ballerina Integrator Markdown files generator

This guide helps to generate markdown files which needs to generate ballerina integrator website using **wso2/docs-ei** 
github repository.

## Instructions to create README.md files

### 1. Include README.md heading

Include heading for the README.md file with `#`. You can have only one main heading with `#`. 
Check following example on how to add the main heading. This should be the very first line and should not use
multiple lines for the main heading.
```
# Asynchronous messaging
```

### 2. Include code

#### (a) Include a code file

Use below syntax to add code files. So when pre-processing markdown files this tag will be replaced with the 
actual code file in the git.
```
<!-- INCLUDE_CODE: guide/http_message_receiver.bal -->
```
When you are mentioning the code file please mention the valid path to the file you want to include.

#### (b) Include a code segment

*README.md file*

```
<!-- INCLUDE_CODE_SEGMENT: { file: guide/http_message_receiver.bal, segment: segment_1 } -->
```

*Code file*

```
// CODE-SEGMENT-BEGIN: segment_1
{code}
// CODE-SEGMENT-END: segment_1
```
***Please note that these syntax are very strict.*

##### Example Usage:

README.md file
```
#### Scheduling an appointment

In the previous tutorial, we called the backend service from the add appointment resource itself. Since we are chaining two services in this example, we will add a util function to handle scheduling appointments at the backend.

<!-- INCLUDE_CODE_SEGMENT: { file: src/tutorial/health_care_service.bal, segment: segment_1 } -->

When the client request is received, we check if the request payload is json. If so, we transform it to the format expected by the backend. Then we invoke the util function to add an appointment within the resource function.

<!-- INCLUDE_CODE_SEGMENT: { file: src/tutorial/health_care_service.bal, segment: segment_3 } -->
```

Code file
```ballerina
// function to call hospital service backend and make an appointment reservation
// CODE-SEGMENT-BEGIN: segment_1
function createAppointment(http:Caller caller, json payload, string category) returns http:Response {
    string hospitalName = payload.hospital.toString();
    http:Request reservationRequest = new;
    reservationRequest.setPayload(payload);
    http:Response | error reservationResponse = new;
    match hospitalName {
        GRAND_OAK => {
            reservationResponse = hospitalEP->
            post("/grandoaks/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        CLEMENCY => {
            reservationResponse = hospitalEP->
            post("/clemency/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        PINE_VALLEY => {
            reservationResponse = hospitalEP->
            post("/pinevalley/categories/" + <@untainted> category + "/reserve", reservationRequest);
        }
        _ => {
            respondToClient(caller, createErrorResponse(500, "Unknown hospital name"));
        }
    }
    return handleResponse(reservationResponse);
}
// CODE-SEGMENT-END: segment_1

// function to call hospital service backend and make payment for an appointment reservation
// CODE-SEGMENT-BEGIN: segment_3
function doPayment(json payload) returns http:Response {
    http:Request paymentRequest = new;
    paymentRequest.setPayload(payload);
    http:Response | error paymentResponse = hospitalEP->post("/healthcare/payments", paymentRequest);
    return handleResponse(paymentResponse);
}
// CODE-SEGMENT-END: segment_3

// util method to handle response
function handleResponse(http:Response | error response) returns http:Response {
    if (response is http:Response) {
        return response;
    } else {
        return createErrorResponse(500, <string> response.toString());
    }
}
```

### 3. Include resources

If you want to add resources like images please create a directory with the name **"resources"** and add all your 
resource files to that directory. 
In the markdown file mention full qualified path of the resource as mentioned below.
```
![alt text](https://raw.githubusercontent.com/pramodya1994/ballerina-integrator/hugo-site/examples/guides/messaging/asynchronous-messaging/resources/Asynchronous_service_invocation.png)
``` 
When you are mentioning the resource file please mention the valid path to the file you want to add.

## Build markdown files to include in mkdocs site

Run below command in your terminal

```
./init.sh 
```
Get markdown files from **www/target/mkdocs-content** directory.
