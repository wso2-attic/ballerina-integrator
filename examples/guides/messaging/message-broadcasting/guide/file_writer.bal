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
import ballerina/mysql;
import ballerina/sql;
import ballerina/io;

// File channel for the CSV file
string filePath = "../resources/appointments.csv";
io:WritableCSVChannel csvch = prepareCSV(filePath);

// JMS lister listening on topic
listener jms:TopicSubscriber subscriberEndpoint = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616",
        acknowledgementMode: "AUTO_ACKNOWLEDGE"   //remove message from broker as soon as it is received
    }, topicPattern = "appointmentTopic");

service jmsListener on subscriberEndpoint {


    // Invoked upon JMS message receive
    resource function onMessage(jms:TopicSubscriberCaller consumer,
    jms:Message message) {
        // Receive message as a text
        var messageText = message.getTextMessageContent();
        if (messageText is string) {
            io:StringReader sr = new(messageText, encoding = "UTF-8");
            json jasonMessage = checkpanic sr.readJson();
            // Write to file
            var result = writeCsv(jasonMessage);
            if (result is error) {
                log:printError("Error occurred while writing csv record :", err = result);
            } else {
                log:printInfo("json record successfully transformed to a csv, file could" +
                " be found in " + filePath);
            }
        } else {
            log:printInfo("Error occurred while reading message " + messageText.reason());
        }
    }
}

function prepareCSV(string path) returns io:WritableCSVChannel {
    io:WritableCSVChannel temp = io:openWritableCsvFile(path);
    string[] headers = ["AppointmentNumber", "AppointmentDate", "Fee", "Doctor", "Hospital", "Patient", "Phone"];
    checkpanic temp.write(headers);
    return temp;
}

function writeCsv(json payload) returns error? {
    log:printInfo("Json to write : " + payload.toString());
    string appointmentNumber = string.convert(<int> payload.appointmentNumber);
    string appointmentDate = <string> payload.appointmentDate;
    string fee = string.convert(<float>payload.fee);
    string doctor = <string> payload.doctor.name;
    string hospital = <string> payload.doctor.hospital;
    string patient = <string> payload.patient.name;
    string phone = <string> payload.patient.phone;

    string[] data = [appointmentNumber, appointmentDate, fee, doctor, hospital, patient, phone];
    check csvch.write(data);
}

function getFields(json rec) returns (string[], string[]) {
    int count = 0;
    string[] headers = [];
    string[] fields = [];
    headers = rec.getKeys();
    foreach var field in headers {
        fields[count] = rec[field].toString();
        count = count + 1;
    }
    return (headers, fields);
}

