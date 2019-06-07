# Gmail Connector
Demonstrate the use of Ballerina's GMail module to send an email to a sepecific email address. 


## Overview
In this example, we will send an appointment request to the service, which will send a generated email to the specified email address. This is done with the help of Ballerina Gmail module.

The Gmail module allows you to send, read and delete emails through the Gmail REST API. It handles OAuth 2.0 authentication. It also provides the ability to read, trash, untrash, delete threads, get the Gmail profile, mailbox history etc. More details can be found in the [Gmail Module](https://github.com/wso2-ballerina/module-gmail/blob/master/Readme.md) repository.

This example requires the Hospital Service to be running in the background, as the Gmail Connector service makes an appointment request call to the backend, which generates the appointment confirmation response. Using this reponse, we generate an email to be sent to the intended recipient. 


## Pre-requisites
- Setup [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- Run the [Hospital-Service]() 
- Obtain AuthTokens to run the sample 
    1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.
    2. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
    3. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**. 
    4. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground if you want to use 
[OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the 
access token and refresh token). 
    5. Click **Create**. Your client ID and client secret appear. 
    6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground). Click on the `OAuth 2.0 configuration`
 icon in the top right corner and click on `Use your own OAuth credentials` and provide your `OAuth Client ID` and `OAuth Client secret`.
    7. Select the required Gmail API scopes from the list of API's, and then click **Authorize APIs**.
    8. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh token and access token.
    9. You can enter the credentials in the HTTP client config when defining the service. 


## Implementation
### - Creating the module structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although the 
language allows you to have any module structure, you can use the following simple module structure for this project.

```
└── using-the-gmail-connector
    ├── resources
        └── request.json
    └── gmail_connector.bal
```

- Create the above directories in your local machine and also create the empty .bal files.
- Then open a terminal, navigate to message_transformation_service, and run the Ballerina project initializing toolkit.
   ```
   $ ballerina init
   ```
Now that you have created the project structure, the next step is to develop the service.

### - Developing the service
Sending emails using the Gmail connector requires you to create a `gmailClient` with the necessary tokens obtained from the Google API Console

```ballerina
gmail:Client gmailClient = new(gmailConfig);

gmail:GmailConfiguration gmailConfig = {
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            config: {
                grantType: http:DIRECT_TOKEN,
                config: {
                    accessToken: testAccessToken,
                    refreshConfig: {
                        refreshUrl: gmail:REFRESH_URL,
                        refreshToken: testRefreshToken,
                        clientId: testClientId,
                        clientSecret: testClientSecret
                    }
                }
            }
        }
    }
};
```

With the defined `gmailClient`, a function to send the mail needs to be defined. The sender and recipient of the email is specified and the client is used to send the message. 

```ballerina

function sendEmail(string email) returns http:Response {
    string messageBody = email;
    http:Response response = new;

    string userId = "me";
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = "someone@gmail.com";
    messageRequest.sender = "somebody@gmail.com";
    messageRequest.subject = "Gmail Connector test : Payment Status";
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    // Send the message.
    var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest);

    if (sendMessageResponse is (string, string)) {
        // If successful, print the message ID and thread ID.
        (string, string) (messageId, threadId) = sendMessageResponse;
        io:println("Sent Message ID: " + messageId);
        io:println("Sent Thread ID: " + threadId);

        json payload = {
            Message: "The email has been successfully sent",
            Recipient: messageRequest.recipient
        };
        response.setJsonPayload(payload, contentType = "application/json");
    } else {
        // If unsuccessful, print the error returned.
        io:println("Error: ", sendMessageResponse);
        response.setPayload("Failed to send the Email");
    }

    return response;
}
```

An optional Email Generator can be defined to send a email with specific data obtained from the response payload

```js
function generateEmail(json jsonPayload) returns string{
    string email = "<html>";
    email += "<h1> GRAND OAK COMMUNITY HOSPITAL </h1>";
    email += "<h3> Patient Name : " + jsonPayload.patient.name.toString() +"</h3>";
    email += "<p> This is a confimation for your appointment with Dr." + jsonPayload.doctor.name.toString() + "</p>";
    email += "<p> Assigned time : " + jsonPayload.doctor.availability.toString() + "</p>";
    email += "<p> Appointment number : " + jsonPayload.appointmentNumber.toString() + "</p>";
    email += "<p> Appointment date : " + jsonPayload.appointmentDate.toString() + "</p>";
    email += "<p><b> FEE : " + jsonPayload.fee.toString() + "</b></p>";

    return email;
}
```


## Deployment
You can build the Ballerina executable archives (.balx) as follows

```bash
$ ballerina build gmail_connector.bal
```

After it successfully builds, you can run the newly generated `gmail_connector.balx` file as follows

```bash
$ ballerina run gmail_connector.balx
```


## Invoking the service
- Create a file called request.json with the following json request

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

- Navigate to `using-the-gmail-connector/resources` and send the request message to the service using cURL

```
curl -v -X POST --data @request.json http://localhost:9090/surgery/reserve --header "Content-Type:application/json"
```


## Output
 A request is made to the `Hospital-Service` which returns a JSON payload with the confirmation details such as the appointment number and fees. 
 
```json 
{
    "appointmentNumber": 1,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "fee": 7000,
    "confirmed": false,
    "appointmentDate": "2025-04-02"
}
```
This payload is used to extract necessary details for the email message using the emailGenerator function.With the necessary `MessageRequest` details specified, the email can be sent to its intended recipient and a reponse is sent back to the caller confirming the receipt of the email. 

```json
{
    "Message": "The email has been successfully sent",
    "Recipient": "someone@gmail.com"
}
```
