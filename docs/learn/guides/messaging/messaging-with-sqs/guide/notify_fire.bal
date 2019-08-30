import ballerina/config;
import ballerina/log;
import ballerina/runtime;
import wso2/amazonsqs;

// periodicallySendFireNotifications, which periodically send fire alerts to Amazon SQS queue
function periodicallySendFireNotifications(string queueResourcePath) {

    // Amazon SQS client configuration
    amazonsqs:Configuration configuration = {
        accessKey: config:getAsString("ACCESS_KEY_ID"),
        secretKey: config:getAsString("SECRET_ACCESS_KEY"),
        region: config:getAsString("REGION"),
        accountNumber: config:getAsString("ACCOUNT_NUMBER")
    };

    // Amazon SQS client
    amazonsqs:Client sqsClient = new(configuration);

    while (true) {

        // Wait for 5 seconds
        runtime:sleep(5000);
        string queueUrl = "";

        // Send a fire notification to the queue
        amazonsqs:OutboundMessage|error response = sqsClient->sendMessage("There is a fire!", 
            queueResourcePath, {});
        // When the response is valid
        if (response is amazonsqs:OutboundMessage) {
            log:printInfo("Sent an alert to the queue. MessageID: " + response.messageId);
        } else {
            log:printError("Error occurred while trying to send an alert to the SQS queue!");
        }
    }

}