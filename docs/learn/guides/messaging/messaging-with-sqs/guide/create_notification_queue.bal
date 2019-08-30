import ballerina/config;
import wso2/amazonsqs;

function createNotificationQueue(string queueName) returns string|error {
    // Amazon SQS client configuration
    amazonsqs:Configuration configuration = {
        accessKey: config:getAsString("ACCESS_KEY_ID"),
        secretKey: config:getAsString("SECRET_ACCESS_KEY"),
        region: config:getAsString("REGION"),
        accountNumber: config:getAsString("ACCOUNT_NUMBER")
    };

    // Amazon SQS client
    amazonsqs:Client sqsClient = new(configuration);

    // Create SQS Standard Queue for notifications
    string|error queueURL = sqsClient->createQueue(queueName, {});
    return queueURL;
}