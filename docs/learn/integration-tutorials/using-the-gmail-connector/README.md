# Gmail Connector

In this tutorial, we will send an email to the user, using the GMail module in Ballerina.

#### What you will build

In the previous tutorial [Exposing Several Services as a Single Service](../../exposing-several-services-as-a-single-service/exposing-several-services-as-a-single-service/), we added the capability to schedule an appointment in the Health Care System and add the payment for it. In this tutorial, we will send a mail to the user to confirm their payment made when scheduling the appointment. This is done with the help of Ballerina Gmail module.

The Gmail module allows you to send, read and delete emails through the Gmail REST API. It handles OAuth 2.0 authentication. It also provides the ability to read, trash, untrash, delete threads, get the Gmail profile and access the mailbox history as well. More details on this module can be found in the [Gmail Module](https://github.com/wso2-ballerina/module-gmail/blob/master/Readme.md) repository.

This example requires the Hospital Service to be running in the background, as the Gmail Connector service makes an appointment request call to the backend, which generates the appointment confirmation response. Using this reponse, we generate an email to be sent to the intended recipient.

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#).
- If you did not try the [Exposing Several Services as a Single Service](../../exposing-several-services-as-a-single-service/exposing-several-services-as-a-single-service/) tutorial yet, you can clone the project from GitHub and follow the steps as mentioned below.

### Let's Get Started!

This tutorial includes the following sections.

- [Implementation](#implementation)
  - [Obtaining auth tokens to access Google APIs](#obtaining-auth-tokens-to-access-google-apis)
  - [Adding Gmail configuration](#adding-gmail-configuration)
  - [Generating mail body](#generating-mail-body)
  - [Sending email to user](#sending-email-to-user)
- [Testing the Implementation](#testing-the-implementation)

### Implementation

#### Obtaining auth tokens to access Google APIs

First, we need to obtain AuthTokens to access Google APIs. Follow the steps below to setup a project for our Health Care System, and get the access keys from Google API Console.

1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.
2. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
3. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**.
4. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground, if you want to use [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the access token and refresh token).
5. Click **Create**. Your client ID and client secret will appear.
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground). Click on the _OAuth 2.0 configuration_ icon in the top right corner and click on **Use your own OAuth credentials** and provide your _OAuth Client ID_ and _OAuth Client secret_.
7. Select the required Gmail API scopes from the list of APIs, and then click **Authorize APIs**.
8. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh token and access token.
9. You can enter the credentials in the HTTP client config when defining the service.

#### Adding Gmail configuration

In the Health Care Service we created in previous tutorials, we can add an HTTP client config for Gmail as below.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

Then we can create the Gmail client using the above config.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_2 } -->

#### Generating mail body

We can use a util function to generate the mail body, based on the response received from the payment endpoint.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_3 } -->

#### Sending email to user

Once the mail body is generated, we can send the email to the user's email address.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_4 } -->

### Testing the Implementation

Let's start the service by navigating to the folder *guide/health_care_service.bal* file is and executing the following command.

```
$ ballerina run health_care_service.bal
```

The 'healthCareService' service will start on port 9092. Now we can send an HTTP request to this service.

Let's create a file called _request.json_ and add the following content.

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

Navigate to _using-the-gmail-connector/guide_ and send the request message to the service using cURL.

```
$ curl -v -X POST --data @request.json http://localhost:9092/hospitalMgtService/surgery/reserve --header "Content-Type:application/json"
```

A request is made to the _healthCareService_ which returns a JSON payload with the confirmation details such as the appointment number and fees.

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

This payload is used to extract necessary details for the email message using the _generateEmail_ function. With the necessary _MessageRequest_ details specified, the email can be sent to its intended recipient and a reponse is sent back to the caller confirming the receipt of the email.

```json
{
  "Message": "The email has been successfully sent",
  "Recipient": "someone@gmail.com"
}
```
