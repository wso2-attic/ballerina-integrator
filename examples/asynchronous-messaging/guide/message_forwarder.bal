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

import ballerina/jms;
import ballerina/log;
import ballerina/http;
import ballerina/io;
listener jms:QueueReceiver consumerEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, queueName = "appointments");

service jmsListener on consumerEndpoint {
    //invoked upon JMS message receive 
    resource function onMessage(jms:QueueReceiverCaller consumer,
    jms:Message message) {
        //receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            http:Client clientEP = new("http://localhost:9090");
            //convert text message received to a Json message and construct request for HTTP service
            http:Request req = new;
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json j = checkpanic sr.readJson();
            //invoke the HTTP service
            var response = clientEP->post("/grandoaks/categories/surgery/reserve ", untaint j);
            //at this point we can only log the response 
            if (response is http:Response) {
                var resPayload = response.getJsonPayload();
                if (resPayload is json) {
                    io:println("Response is : " + resPayload.toString());
                } else {
                    io:println("Error1 " + <string> resPayload.detail().message);
                }
            } else {
                io:println("Error2 " + <string> response.detail().message);
            }
        } else {
            io:println("Error occurred while reading message ", messageText);
        }
    }
}
