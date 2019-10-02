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
import wso2/sap;

listener sap:Listener consumer = new (
    {
        // `transportName` property decides whether the consumer listens on BAPI or IDoc.
        transportName: <sap:Transport>config:getAsString("TRANSPORT_NAME"),
        serverName: config:getAsString("SERVER_NAME"),
        gwhost: config:getAsString("GWHOST"),
        progid: config:getAsString("PROGRAM_ID"),
        repositorydestination: config:getAsString("REPOSITORY_DESTINATION"),
        gwserv: config:getAsString("GWSERVER"),
        unicode: <sap:Value>config:getAsInt("UNICODE")
    },
    {
        sapclient: config:getAsString("SAP_CLIENT"),
        username: config:getAsString("USERNAME"),
        password: config:getAsString("PASSWORD"),
        ashost: config:getAsString("ASHOST"),
        sysnr: config:getAsString("SYSNR"),
        language: config:getAsString("LANGUAGE")
    }
);

service SapConsumerTest on consumer {
    // The `resource` registered to receive server messages
    resource function onMessage(string message) {
        io:println("Message received from SAP instance: " + message);
    }

    // The `resource` registered to receive server error messages
    resource function onError(error err) {
        io:println(err.detail()?.message);
    }
}
