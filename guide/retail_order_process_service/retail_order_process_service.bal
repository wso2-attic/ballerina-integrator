import ballerina/log;
import ballerina/jms;


// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a retail queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session:jmsSession,
    queueName:"Retail_Queue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDispatcherService bind jmsConsumer {
    // Triggered whenever an order is added to the 'Order_Queue'
    onMessage(endpoint consumer, jms:Message message) {

        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var orderDetails = check message.getTextMessageContent();
        log:printInfo("below retail order has been successfully processed");
        log:printInfo(orderDetails);

    }
}
