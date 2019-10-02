# Using the Gmail Connector

## About
Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on how the Ballerina Gmail connector could be used for handling emails.

The Ballerina Gmail connector allows you to send, read, and delete emails through the Gmail REST API. It also provides the ability to read, trash, untrash, and delete threads, get the Gmail profile, and access the mailbox history as well, while handling OAuth 2.0 authentication. More details on this module can be found in the [Gmail Module](https://github.com/wso2-ballerina/module-gmail/blob/master/Readme.md) repository.

You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

## What you'll build
This tutorial demonstrates a scenario where a customer feedback Gmail account of a company can be easily managed using the Ballerina Gmail Connector. This application contains a service that can be invoked through an HTTP GET request. Once the service is invoked, it returns the contents of unread emails in the `Inbox`, while sending an automated response to the customer, thanking them for their feedback. The number of emails that can be handled in a single invocation is specified in the application.

## Prerequisites
- [Java](https://www.oracle.com/technetwork/java/index.html)
- Ballerina Integrator
- A Text Editor or an IDE
> **Tip**: For a better development experience, install the `Ballerina Integrator` extension in [VS Code](https://code.visualstudio.com/).

## Implementation

#### Obtaining auth tokens to access Google APIs

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping the `Implementation` section.

First, we need to obtain AuthTokens to access Google APIs. Follow the steps below to get the access keys from Google API Console.

1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.
2. Go to **Credentials -> OAuth Consent Screen**, enter a product name to be shown to users and click **Save**.
3. On the **Credentials** tab, click **Create Credentials** and select **OAuth Client ID**.
4. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground, if you want to use [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the access token and refresh token).
5. Click **Create**. Your client ID and client secret will appear.
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground). Click on the _OAuth 2.0 configuration_ icon in the top right corner and click on **Use your OAuth credentials** and provide your _OAuth Client ID_ and _OAuth Client secret_.
7. Select the required Gmail API scopes from the list of APIs, and then click **Authorize APIs**.
8. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh token and access token.
9. You can enter the credentials in the HTTP client config when defining the service.

Create a project.
```bash
ballerina new using-the-gmail-connector
```
Navigate to the project directory and add a module using the following command.
```bash
ballerina add gmail_client_application
```

Add a `ballerina.conf` file and create .bal files with meaningful names as shown in the project structure given below.
```
using-the-gmail-connector
├── Ballerina.toml
├── ballerina.conf
└── src
    └── gmail_client_application
        ├── Module.md
        ├── gmail_client.bal
        ├── resources
        └── tests
            ├── resources
            └── gmail_client_test.bal
```

Update the `ballerina.conf` file with the token configuration required for accessing the Gmail account.
```
ACCESS_TOKEN = ""
CLIENT_ID = ""
CLIENT_SECRET = ""
REFRESH_TOKEN = ""
```

You can open the project with VS Code. The integration implementation is written in the `gmail_client.bal` file.

The code segment given below can be used to create a Gmail client. Ballerina Integrator VS Code plugin contains a snippet for the same, which can be loaded using the autocomplete feature for the `client/gmail` keyword.

```ballerina
gmail:GmailConfiguration gmailConfig = {
    oauthClientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            refreshUrl: gmail:REFRESH_URL,
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET")
        }
    }
};

gmail:Client gmailClient = new(gmailConfig);
```

## Testing

Let’s build the module. Navigate to the project directory and execute the following command.

```bash
$ ballerina build gmail_client_application
```

The build command creates an executable .jar file. Now run the .jar file created in the above step. Path to the `ballerina.conf` could be provided using the `--b7a.config.file` option.

```bash
$ java -jar target/bin/gmail_client_application.jar --b7a.config.file=path/to/ballerina.conf/file
```
Now we can see that the service has started on port 9090. Let’s invoke this service by executing the following cURL command.
```
curl -X GET http://localhost:9090/gmail/reviews
```
You will see the list of email body contents during a successful invocation.

### Writing unit tests

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`. When writing test functions the convention given below should be followed.

Test functions should be annotated with `@test:Config {}`. See the example below.
```ballerina
@test:Config {}
function testSendTextMessage() {
}
```

This guide contains unit tests for the Gmail application in the `gmail_client_test.bal`.

To run the unit tests, navigate to the project directory and run the following command.
```
ballerina test
```
> **Note:** The `--b7a.config.file=path/to/ballerina.conf/file` option is required if it is needed to read configurations from a Ballerina configuration file.
