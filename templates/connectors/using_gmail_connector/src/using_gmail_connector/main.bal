// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/io;
import wso2/gmail;

// Setting the OAuth Client configuration.
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

// Initializing a Gmail client.
gmail:Client gmailClient = new (gmailConfig);

string recipient = config:getAsString("RECIPIENT");
string sender = config:getAsString("SENDER");
string cc = config:getAsString("CC");
string attachmentPath = config:getAsString("ATTACHMENT_PATH");
string attachmentContentType = config:getAsString("ATTACHMENT_CONTENT_TYPE");
string inlineImagePath = config:getAsString("INLINE_IMAGE_PATH");
string inlineImageName = config:getAsString("INLINE_IMAGE_NAME");
string imageContentType = config:getAsString("IMAGE_CONTENT_TYPE");
string userId = config:getAsString("USER_ID");
string emailId = "123456";

public function main() {
    // Sends an email
    var sentEmail = sendEmail();
    if (sentEmail is error) {
        io:println(sentEmail.detail()?.message);
    } else {
        emailId = <@untainted>sentEmail.toString();
        io:println("Message ID: " + emailId);
    }

    // Reads an email
    readEmail(emailId);

    // Deletes an email
    deleteEmail(emailId);
}

public function sendEmail() returns @tainted string | error? {
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = recipient;
    messageRequest.sender = sender;
    messageRequest.cc = cc;
    messageRequest.subject = "Text-Email-Subject";
    //---Set Text Body---
    messageRequest.messageBody = "Text Message Body";
    messageRequest.contentType = gmail:TEXT_PLAIN;
    //---Set Attachments---
    gmail:AttachmentPath[] attachments = [{attachmentPath: attachmentPath, mimeType: attachmentContentType}];
    messageRequest.attachmentPaths = attachments;
    //----Send the Mail----
    var sendMessageResponse = check gmailClient->sendMessage(userId, messageRequest);
    string messageId = "";
    string threadId = "";
    [messageId, threadId] = sendMessageResponse;
    return messageId;
}

public function readEmail(string emailId) {
    var response = gmailClient->readMessage(userId, emailId);
    if (response is gmail:Message) {
        io:println("Email: " + response.toString());
    } else {
        io:println(response.detail()?.message);
    }
}

public function deleteEmail(string emailId) {
    var delete = gmailClient->deleteMessage(userId, emailId);
    if (delete is boolean) {
        io:println("Deleted Email: " + emailId);
    } else {
        io:println(delete.detail()?.message);
    }
}
