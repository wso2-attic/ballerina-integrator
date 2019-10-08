# Using the Gmail Connector

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on how the Ballerina Gmail connector could be used for handling emails.

The Ballerina Gmail connector allows you to send, read, and delete emails through the Gmail REST API. It also provides the ability to read, trash, untrash, and delete threads, get the Gmail profile, and access the mailbox history as well, while handling OAuth 2.0 authentication. More details on this module can be found in the [Gmail Module](https://github.com/wso2-ballerina/module-gmail/blob/master/Readme.md) repository.

You can find other integration modules from the [wso2-ballerina](https://github.com/wso2-ballerina) GitHub repository.

## What you'll build
This tutorial demonstrates a scenario where a customer feedback Gmail account of a company can be easily managed using the Ballerina Gmail Connector. This application contains a service that can be invoked through an HTTP GET request. Once the service is invoked, it returns the contents of unread emails in the `Inbox`, while sending an automated response to the customer, thanking them for their feedback. The number of emails that can be handled in a single invocation is specified in the application.

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

#### 1. Obtaining auth tokens to access Google APIs

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

#### 2. Creating the project structure

Create a project.
```bash
ballerina new using-the-gmail-connector
```
Navigate to the project directory and add a module using the following command.
```bash
ballerina add gmail_client_application
```
Project structure is created as indicated below.
```
using-the-gmail-connector
├── Ballerina.toml
└── src
    └── gmail_client_application
        ├── Module.md
        ├── gmail_client.bal
        ├── resources
        └── tests
            └── resources
```

#### 3. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure.
Update the `ballerina.conf` file with the token configuration required for accessing the Gmail account.
```
ACCESS_TOKEN = ""
CLIENT_ID = ""
CLIENT_SECRET = ""
REFRESH_TOKEN = ""
```

#### 4. Write the integration

You can open the project with VS Code. The integration implementation is written in the `gmail_client.bal` file.

**gmail_client.bal**
<!-- INCLUDE_CODE: src/gmail_client_application/gmail_client.bal -->

## Testing

Let’s build the module. Navigate to the project directory and execute the following command.

```bash
$ ballerina build gmail_client_application
```

The build command creates an executable .jar file. Now run the .jar file created in the above step.

```bash
$ java -jar target/bin/gmail_client_application.jar
```
Now we can see that the service has started on port 9090. Let’s invoke this service by executing the following cURL command.
```
$ curl -X GET http://localhost:9090/gmail/reviews
```
You will see the list of email body contents during a successful invocation.
