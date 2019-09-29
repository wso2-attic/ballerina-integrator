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
import ballerina/io;
import ballerina/config;
import ballerina/http;

// Util function to read a json file.
public function readJsonFile(io:ReadableByteChannel result) returns json|error {

    io:ReadableCharacterChannel? charChannelResult = getCharChannel(result);
    var resultJson = charChannelResult.readJson();

    if (resultJson is json) {
        io:println("File content: ", resultJson);
        return resultJson;
    } else {
        log:printError("An error occured.", err = resultJson);
        return resultJson;
    }
}

// Util function to read a xml file.
public function readXmlFile(io:ReadableByteChannel result) returns xml|error? {

    io:ReadableCharacterChannel? charChannelResult = getCharChannel(result);
    var resultXml = charChannelResult.readXml();

    if (resultXml is xml) {
        io:println("File content: ", resultXml);
        return resultXml;
    } else {
        log:printError("An error occured.", err = resultXml);
        return resultXml;
    }
}

// Util function to convert a byte channel to a character channel.
public function getCharChannel(io:ReadableByteChannel getResult) returns io:ReadableCharacterChannel? {

    io:ReadableCharacterChannel? charChannel = new io:ReadableCharacterChannel(getResult, "utf-8");

    if (charChannel is io:ReadableCharacterChannel) {
        return charChannel;
    } else {
        log:printError("An error occured.");
        return;
    }
}

