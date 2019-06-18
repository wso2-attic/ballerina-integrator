import ballerina/log;
import ballerina/io;
import ballerina/config;
import ballerina/http;

public function readJsonFile(io:ReadableByteChannel result) returns json {

    io:ReadableCharacterChannel? charChannelResult = getCharChannel(result);
    var resultJson = charChannelResult.readJson();

    if (resultJson is json) {
        io:println("File content: ", resultJson);
        return resultJson;
    } else {
        log:printError("An error occured.", err = resultJson);
        return;
    }   
}

public function getCharChannel(io:ReadableByteChannel getResult) returns io:ReadableCharacterChannel? {

    io:ReadableCharacterChannel? charChannel = new io:ReadableCharacterChannel(getResult, "utf-8");

    if (charChannel is io:ReadableCharacterChannel) {
        return charChannel;
    } else {
        log:printError("An error occured.");
        return;
       }
}

