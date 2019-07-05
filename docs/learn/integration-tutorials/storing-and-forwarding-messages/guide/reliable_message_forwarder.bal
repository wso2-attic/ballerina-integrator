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

import ballerina/log;
import ballerina/http;
import wso2/messageStore;
import ballerina/runtime;
import ballerina/io;

// File channel for the CSV file
string filePath = "../resources/appointments.csv";
io:WritableCSVChannel csvch = prepareCSV(filePath);

public function main(string... args) {

    messageStore:MessageStoreConfiguration myMessageStoreConfig = {
        messageBroker: "ACTIVE_MQ",
        providerUrl: "tcp://localhost:61616",
        queueName: "myStore"
    };

    //create a DLC store
    messageStore:MessageStoreConfiguration dlcMessageStoreConfig = {
        messageBroker: "ACTIVE_MQ",
        providerUrl: "tcp://localhost:61616",
        queueName: "myDLCStore"
    };

    messageStore:Client dlcStoreClient = checkpanic new messageStore:Client(dlcMessageStoreConfig);

    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HTTPEndpoint: "http://localhost:9090/grandoaks/categories/surgery/reserve",
        
        pollTimeConfig: "0/2 * * * * ?" , 

        //forwarding retry 
        retryInterval: 3000,
        retryHTTPStatusCodes:[500,400],
        maxRedeliveryAttempts: 5,
        
        //connection retry 
        maxStoreConnectionAttemptInterval: 120,
        storeConnectionAttemptInterval: 15,
        storeConnectionBackOffFactor: 1.5,

        deactivateOnFail: false,
        
        DLCStore: dlcStoreClient

    };

    //create message processor 
    var myMessageProcessor = new messageStore:MessageForwardingProcessor(myProcessorConfig, handleResponseFromBE);
    if(myMessageProcessor is error) {
        log:printError("Error while initializing Message Processor", err = myMessageProcessor);
        panic myMessageProcessor;
    } else {
        //start the processor
        var processorStartResult = myMessageProcessor.start();
        if(processorStartResult is error) {
            panic processorStartResult;
        } else {
            //TODO:temp fix
            myMessageProcessor.keepRunning();
        }
    }   
}


//function to handle response
function handleResponseFromBE(http:Response resp) {
    var payload =  resp.getJsonPayload();
    if(payload is json) {
        log:printInfo("Response received " + "Response status code= "+ resp.statusCode + ": "+ payload.toString());
        // Write to file
        var result = writeCsv(payload);
        if (result is error) {
            log:printError("Error occurred while writing csv record :", err = result);
        } else {
            log:printInfo("json record successfully transformed to a csv, file could" +
            " be found in " + filePath);
        }
    } else {
        log:printError("Error while getting response payload", err=payload);
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
