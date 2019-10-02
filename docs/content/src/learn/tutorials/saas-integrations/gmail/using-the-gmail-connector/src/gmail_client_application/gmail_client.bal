// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/http;
import ballerina/lang.'array as arrays;
import ballerina/lang.'string as strings;
import ballerina/log;
import wso2/gmail;

// Gmail client endpoint declaration with OAuth2 client configurations.
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

// Creating a new Gmail client.
gmail:Client gmailClient = new (gmailConfig);

// Assume a Gmail account created for obtaining customer reviews.
// This service would allow the manager of the Gmail account to retrieve the content of
// unread emails in the Gmail `Inbox` through an HTTP GET request. The customer will be sent a reply.
@http:ServiceConfig {
    basePath: "/gmail"
}
service gmailService on new http:Listener(9090) {
    // `reviews` resource allows the gmail account manager to send an automated reply and return
    // the content of unread emails in the Gmail `Inbox`.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/reviews"
    }
    resource function getReviews(http:Caller caller, http:Request request) returns error? {

        // The accounts's email address. Special value **me** can be used to indicate the authenticated user.
        string userId = "me";
        string inboxLabel = "INBOX";

        // A search filter is used to to filter out emails inside the "Inbox".
        gmail:MsgSearchFilter searchFilter = {includeSpamTrash: false, labelIds: [inboxLabel]};
        // Obtains the list of emails that statisfy the above search filter.
        gmail:MessageListPage mailList = check gmailClient->listMessages(userId, searchFilter);

        string attachmentPath = "src/gmail_client_application/resources/email.png";
        string attachmentType = "image/jpeg";
        string sender = "sender@gmail.com";
        string response = "";
        int i = 1;

        // Iterating through each email in the list retrieved.
        foreach json email in mailList.messages {
            string messageId = <@untainted><string>email.messageId;
            string threadId = <@untainted><string>email.threadId;

            // Reads the email using its message id.
            gmail:Message message = check gmailClient->readMessage(userId, messageId);

            string recipient = <@untainted>message.headerFrom;
            string subject = <@untainted>message.headerSubject;

            // Creating the message request for the reponse email.
            gmail:MessageRequest messageRequest = {};
            messageRequest.subject = subject;
            messageRequest.recipient = recipient;
            messageRequest.sender = sender;
            messageRequest.messageBody = "Thank you for your valuable feedback!";
            messageRequest.contentType = gmail:TEXT_PLAIN;
            gmail:AttachmentPath[] attachments = [{attachmentPath: attachmentPath, mimeType: attachmentType}];
            messageRequest.attachmentPaths = attachments;

            // Sending the response mail.
            var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest, threadId);
            if (sendMessageResponse is [string, string]) {
                log:printInfo("Email sent successfully to " + recipient);
            } else {
                log:printError("Unable to send the email to " + recipient);
            }

            // Retrieve the body of the email.
            json jsonMessage = check json.constructFrom(message);
            json jsonMessageBody = check jsonMessage.plainTextBodyPart.body;
            byte[] | error body = arrays:fromBase64(jsonMessageBody.toString());
            if (body is byte[]) {
                string finalString = check strings:fromBytes(body);
                // Append the body to the HTTP response.
                response = response + "Email " + i.toString() + ": " + finalString + "\n\n";
            }
            i = i + 1;

            // Remove the email from Gmail `Inbox` by removing the tag. The email would move to `All Mails` section.
            gmail:Message modifiedMessage = check gmailClient->modifyMessage(userId, messageId, [], [inboxLabel]);

            // Control the amount of emails processed in a single HTTP client request.
            if (i > 5) {
                // Send the response back to the caller.
                var result = caller->respond(<@untainted>response);
                if (result is error) {
                    log:printError(result.detail()?.message.toString());
                }
                return;
            }
        }
    }
}
