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

##### Example Usage:

README.md file
```
#### Scheduling an appointment

In the previous tutorial, we called the backend service from the add appointment resource itself. Since we are chaining 
two services in this example, we will add a util function to handle scheduling appointments at the backend.

<!-- INCLUDE_CODE: src/tutorial/health_care_service.bal -->
```

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

In the previous tutorial, we called the backend service from the add appointment resource itself. Since we are chaining 
two services in this example, we will add a util function to handle scheduling appointments at the backend.

<!-- INCLUDE_CODE_SEGMENT: { file: src/tutorial/health_care_service.bal, segment: segment_1 } -->

When the client request is received, we check if the request payload is json. If so, we transform it to the format 
expected by the backend. Then we invoke the util function to add an appointment within the resource function.

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

### 3. Include markdown content

Use below syntax to add markdown files. So when pre-processing `README.md` files this tag will be replaced with the 
actual markdown file content given in `INCLUDE_MD` tag.
```
<!-- INCLUDE_MD: path/to/file/prerequisites.md -->
```

### 4. Include images

If you want to add images and add image attachments to your `README.md` file add all the images to `docs/assets/img`
and add the image attachment in the `README.md` file.

When you are adding images: 
  
- Add image attachment as a new line in the `README.md`.
    ```
    ![alt text](../../../../assets/img/pass-through-messaging-1.svg)
    ```
- Do not use `[`, `]`, `(`, `)` to name images and for image alt text.
    > **Tip**: "pass-through-messaging[1].svg" is not allowed.
 
When you are mentioning the resource file please mention the valid path to the file you want to add.

## Build website

#### Prerequisites

 - Install [Docker](https://docs.docker.com/install/)
 - Install [Apache Maven](https://maven.apache.org/install.html)

#### Generate website content

Navigate to `docs/doc-generator` and run below command.

```bash
$ cd docs/doc-generator
$ mvn clean install
```

This will generate website content inside `docs/doc-generator/target/www`.

#### Testing the website

Navigate to `docs/doc-generator` directory and run below command.

```bash
docker run --rm -it -p 8000:8000 -v ${PWD}/target/www:/docs squidfunk/mkdocs-material
```

You will see following log in the terminal. You can go to the serving Url and check your guide.

```
Serving on http://0.0.0.0:8000
```
