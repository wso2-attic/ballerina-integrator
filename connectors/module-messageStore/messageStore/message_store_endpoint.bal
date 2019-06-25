import ballerina/jms;
import ballerina/http;
import ballerina/log;
public type Client client object {

    jms:Connection jmsConnection;
    jms:Session jmsSession;
    jms:QueueSender queueSender;

    Client? failoverStore;

    string queueName;

    public function __init(MessageStoreConfiguration storeConfig, boolean enableGuranteedDelivery = false, Client? failoverStore = ()) returns error? {
        string providerUrl = storeConfig.providerUrl;
        self.queueName = storeConfig.queueName;
        self.failoverStore = failoverStore;
        
        string? userName = storeConfig["userName"];
        string? password = storeConfig["password"];

        string acknowledgementMode = "AUTO_ACKNOWLEDGE";
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);


        // This initializes a JMS connection with the provider.
        self.jmsConnection = new({
                initialContextFactory: initialContextFactory,
                providerUrl: providerUrl
            });

        // This initializes a JMS session on top of the created connection.
        self.jmsSession = new(self.jmsConnection, {
                acknowledgementMode: acknowledgementMode
            });

        // This initializes a queue sender.
        self.queueSender = new(self.jmsSession, queueName = self.queueName);
    }

    public remote function store(http:Request request) returns error? {
        map<string> requestMessageMap = {};
        string [] httpHeaders = request.getHeaderNames();
        foreach var headerName in httpHeaders {
            requestMessageMap[headerName] = request.getHeader(untaint headerName);
        }
        //set payload as an entry to the map message
        string payloadAsText = check request.getTextPayload();
        requestMessageMap[PAYLOAD] =  payloadAsText;
        
        //create a map message from message detail extracted 
        var messageToStore = self.jmsSession.createMapMessage(requestMessageMap);

        if (messageToStore is jms:Message) {
            // This sends the Ballerina message to the JMS provider.
            var returnVal = self.queueSender->send(messageToStore);
            if (returnVal is error) {
                //TODO: try to send to failover store if defined 
                string errorMessage = "Error occurred while sending the message to the queue " + self.queueName;
                log:printError(errorMessage);
                Client? failoverClient = self.failoverStore;
                //try failover store
                if(failoverClient is Client) {
                    check failoverClient->store(request);
                //return error(MESSAGE_STORE_ERROR_CODE,{ message:errorMessage});
                }
            }
        }
    }
};

public type MessageStoreConfiguration record {
    MessageBroker messageBroker;
    string providerUrl;
    string queueName;
    string userName?;
    string password?;
};

