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
import ballerina/log;
import ballerina/test;
import wso2/gmail;

//Create an endpoint to use Gmail Connector
gmail:GmailConfiguration gmailTestConfig = {
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

gmail:Client gmailTestClient = new (gmailTestConfig);

// Provide the following in the ballerina.conf file before running the tests.
string testRecipient = config:getAsString("RECIPIENT");//Example: "recipient@gmail.com"
string testSender = config:getAsString("SENDER");//Example: "sender@gmail.com"
string testCc = config:getAsString("CC");//Example: "cc@gmail.com"
string testAttachmentPath = config:getAsString("ATTACHMENT_PATH");//Example: "/home/user/hello.txt"
string attachmentContentType = config:getAsString("ATTACHMENT_CONTENT_TYPE");//Example: "text/plain"

string testUserId = "me";
//Holds value for message id of text mail sent in testSendTextMessage()
string sentTextMessageId = "";
//Holds value for thread id of text mail sent in testSendTextMessage()
string sentTextMessageThreadId = "";
//Holds value for message id of the html mail sent in testSendHtmlMessage()
string sentHtmlMessageId = "";
//Holds value for history id of the text message sent in testSendTextMessage()
//History id is set in testReadTextMessage()
string testHistoryId = "";

@test:Config {}
function testSendTextMessage() {
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = testRecipient;
    messageRequest.sender = testSender;
    messageRequest.cc = testCc;
    messageRequest.subject = "Text-Email-Subject";
    //---Set Text Body---
    messageRequest.messageBody = "Text Message Body";
    messageRequest.contentType = gmail:TEXT_PLAIN;
    //---Set Attachments---
    gmail:AttachmentPath[] attachments = [{attachmentPath: testAttachmentPath, mimeType: attachmentContentType}];
    messageRequest.attachmentPaths = attachments;
    log:printInfo("testSendTextMessage");
    //----Send the Email----
    var sendMessageResponse = gmailTestClient->sendMessage(testUserId, messageRequest);
    if (sendMessageResponse is [string, string]) {
        [string, string][messageId, threadId] = sendMessageResponse;
        sentTextMessageId = <@untainted>messageId;
        sentTextMessageThreadId = <@untainted>threadId;
        test:assertTrue(messageId != "null" && threadId != "null", msg = "Send Text Message Failed");
    } else {
        test:assertFail(msg = <string>sendMessageResponse.detail()["message"]);
    }
}

@test:Config {
    dependsOn: ["testSendTextMessage"]
}
function testReadTextMessage() {
    //Read email with message id which was sent in testSendTextMessage
    log:printInfo("testReadTextMessage");
    var response = gmailTestClient->readMessage(testUserId, sentTextMessageId);
    if (response is gmail:Message) {
        testHistoryId = <@untainted>response.historyId;
        test:assertEquals(response.id, sentTextMessageId, msg = "Read text mail failed");
    } else {
        test:assertFail(msg = <string>response.detail()["message"]);
    }
}

@test:Config {}
function testListMessages() {
    //List All Messages with Label INBOX without including Spam and Trash.
    log:printInfo("testListMessages");
    gmail:MsgSearchFilter searchFilter = {includeSpamTrash: false, labelIds: ["INBOX"]};
    var msgList = gmailTestClient->listMessages("me", searchFilter);
    if msgList is error {
        test:assertFail(msg = <string>msgList.detail()["message"]);
    }
}

@test:Config {
    dependsOn: ["testSendTextMessage"]
}
function testModifyHTMLMessage() {
    //Modify labels of the message with message id which was sent in testSendTextMessage.
    log:printInfo("testModifyHTMLMessage");
    var response = gmailTestClient->modifyMessage(testUserId, sentHtmlMessageId, ["INBOX"], []);
    if (response is gmail:Message) {
        test:assertTrue(response.id == sentHtmlMessageId, msg = "Modify HTML message by adding new label failed");
    } else {
        test:assertFail(msg = <string>response.detail()["message"]);
    }
    response = gmailTestClient->modifyMessage(testUserId, sentHtmlMessageId, [], ["INBOX"]);
    if (response is gmail:Message) {
        test:assertTrue(response.id == sentHtmlMessageId,
        msg = "Modify HTML message by removing existing label failed");
    } else {
        test:assertFail(msg = <string>response.detail()["message"]);
    }
}
