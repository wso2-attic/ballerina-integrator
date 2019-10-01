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
