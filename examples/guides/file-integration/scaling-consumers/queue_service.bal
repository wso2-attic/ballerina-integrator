import ballerina/log;
import ballerina/io;
// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conne = new({
         initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
         providerUrl:"tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSessionRes = new(conne, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session
listener jms:QueueReceiver jmsConsumer1 = new(jmsSessionRes, queueName = "FileQueue");


service fileConsumingSystems on jmsConsumer1 {
    // Triggered whenever an order is added to the 'FileQueue'
    resource function onMessage(jms:QueueReceiverCaller consumers, jms:Message messages) {
        log:printInfo("New File received from the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = messages.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("File Details: " + stringPayload);

            //processing logic
            var proRes = processFile(stringPayload);

            // Moving the file to another location on the same ftp server after processing.
            if (proRes == MOVE) {
                string destFilePath = createFolderPath(stringPayload, conf.destFolder);
                error? renameErr = ftpClient->rename(stringPayload, destFilePath);
            } else if (proRes == DELETE) {
                error? fileDelCreErr = ftpClient->delete(stringPayload);
                log:printInfo("Deleted File after processing");
            } else {
                string errFoldPath = createFolderPath(stringPayload, conf.errFolder);
                error? processErr = ftpClient->rename(stringPayload, errFoldPath);
            }
        } else {
            log:printInfo("Error occurred while retrieving the order details");
        }       
    }
}