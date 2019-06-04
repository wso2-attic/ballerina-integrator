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
import ballerina/mysql;
import ballerina/sql;

// JMS listener listening on topic
listener jms:TopicSubscriber subscriberEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, topicPattern = "appointmentTopic");

// MySQL DB client configuration
mysql:Client healthcareDB = new({
        host: "localhost",
        port: 3306,
        name: "healthcare",
        username: "wso2",
        password: "wso2",
        dbOptions: { useSSL: false }
    });

service jmsListener on subscriberEndpoint {
    // Invoked upon JMS message receive
    resource function onMessage(jms:TopicSubscriberCaller consumer,
    jms:Message message) {
        // Receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json jsonMessage = checkpanic sr.readJson();
            // Write to database
            writeToDB(jsonMessage);

        } else {
            log:printError("Error occurred while reading message " + messageText.reason());
        }
    }
}

function writeToDB(json payload) {
    log:printInfo("Adding appointment details to the database: " + payload.toString());

    //{"appointmentNumber":4, "doctor":{"name":"thomas collins", "hospital":"grand oak community hospital",
    //"category":"surgery", "availability":"9.00 a.m - 11.00 a.m", "fee":7000.0}, "patient":{"name":"John Doe",
    // "dob":"1940-03-19", "ssn":"234-23-525", "address":"California", "phone":"8770586755", "email":"johndoe@gmail.com"},
    // "fee":7000.0, "confirmed":false, "appointmentDate":"2025-04-02"}
    int appointmentNumber = <int> payload.appointmentNumber;
    string appointmentDate = <string> payload.appointmentDate;
    int fee = <int> payload.fee;
    string doctor = <string> payload.doctor.name;
    string hospital = <string> payload.doctor.hospital;
    string patient = <string> payload.patient.name;
    string phone = <string> payload.patient.phone;

    string sqlString = "INSERT INTO APPOINTMENTS (AppointmentNumber, 
        AppointmentDate, Fee, Doctor, Hospital, Patient, Phone) VALUES (?,?,?,?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var result = healthcareDB->update(sqlString, appointmentNumber, appointmentDate, fee, doctor, hospital, patient, phone);
    handleUpdate(result, "Insert to appointment table");
}

function handleUpdate(sql:UpdateResult | error returned, string message) {
    if (returned is sql:UpdateResult) {
        log:printInfo(message + " status: " + returned.updatedRowCount);
    } else {
        log:printInfo(message + " failed: " + <string>returned.detail().message);
    }
}
