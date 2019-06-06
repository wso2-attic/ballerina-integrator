# Implement Gmail Connector Tutorial
This sample demonstrates the use of Ballerina's GMail module to send an email to an email address. 


## Module Overview 
The Gmail connector allows you to send, read and delete emails through the Gmail REST API. It handles OAuth 2.0 authentication. It also provides the ability to read, trash, untrash, delete threads, get the Gmail profile, mailbox history etc. More details can be found in the [Gmail Module](https://github.com/wso2-ballerina/module-gmail/blob/master/Readme.md) repository

### Pre-requisites
- Setup [Ballerina 0.991.0](https://ballerina.io/downloads/)
- Run the [Hospital-Service]() 
- Obtain AuthTokens to run the sample 

#### Obtaining Tokens to run the Sample
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

You can now enter the credentials in the HTTP client config. 
```ballerina
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

gmail:Client gmailClient = new(gmailConfig);
```

## How it works
In this example, we make use of the GMail connector to send a confirmation email regarding the payment status of a doctor's appointment.


A JSON payload containing the necessary details is sent to the service. 

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

 A request is made to the `Hospital-Service` which returns a JSON payload with the confirmation details such as the appointment number and fees. 
 
 This payload can be used to generate a professional looking email, but for now we will just be sending it unaltered

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
With the necessary `MessageRequest` details specified, the payload can be sent to its intended recipient and a reponse is sent back to the caller confirming the receipt of the email. 

```json
{
    "Message": "The email has been successfully sent",
    "Recipient": "someone@gmail.com"
}
```
