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

import ballerina/http;
import ballerina/log;
import wso2/jms;

jms:Connection connection = check jms:createConnection({
                        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
                         providerUrl: "tcp://localhost:61616"
                        });
jms:Session session = check connection->createSession({acknowledgementMode: "AUTO_ACKNOWLEDGE"});
jms:Destination queue = check session->createQueue("sales");
jms:MessageProducer activemq = check session.createProducer(queue);

@http:ServiceConfig {
    basePath: "sales"
}
service sales on new http:Listener(8080) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/orders"
    }
    resource function addOrder(http:Caller caller, http:Request request) returns error? {
        http:Response response = new();
        string salesOrder = check request.getTextPayload();
        jms:TextMessage message = check session.createTextMessage(salesOrder);
        error? jmsResult = activemq->send(message);
        if (jmsResult is error) {
            response.setJsonPayload({Message: "Error in sending sales order to queue.", Reson: jmsResult.reason()});  
        } else {
            log:printInfo("Sales Order : " + salesOrder);
            response.setJsonPayload({Message: "Order sent for processing."});
        }
        var httpResult = caller->respond(response);
    }
}
