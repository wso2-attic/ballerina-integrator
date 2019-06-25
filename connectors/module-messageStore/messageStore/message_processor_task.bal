import ballerina/jms;
import ballerina/task;
import ballerina/log;
import ballerina/runtime;
import ballerina/math;


//TODO: for remote functions is it mandatory to have Client type?
public type MessageForwardingProcessor object {

    ForwardingProcessorConfiguration processorConfig;

    jms:Connection jmsConnection;
    jms:Session jmsSession;
    public jms:QueueReceiver queueReceiver;

    http:Client httpClient;

    //task driving the message polling from the broker and forward 
    task:Scheduler messageForwardingTask;

    //constructor for ForwardingProcessor
    public function __init(ForwardingProcessorConfiguration processorConfig, 
        function (http:Response resp) handleResponse) returns error? {

        self.processorConfig = processorConfig;

        MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
        string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker); 
        string acknowledgementMode = "CLIENT_ACKNOWLEDGE"; 
        string queueName = storeConfig.queueName;

        //init connection to the broker
        var consumerInitResult = check initializeConsumer(storeConfig);
        (self.jmsConnection, self.jmsSession, self.queueReceiver) = consumerInitResult; 

        //init HTTP endpoint
        self.httpClient = check self.initializeHTTPClient(processorConfig);

        // Check if a cron is mentioned in config. If so, it gets priority
        string|int currentpollTimeConfig = processorConfig.pollTimeConfig;
        if(currentpollTimeConfig is string) {
            self.messageForwardingTask = new({appointmentDetails: currentpollTimeConfig});
        } else {
            self.messageForwardingTask = new({interval: currentpollTimeConfig});
        }

        
        //create a record with objects needed by the polling service 
        PollingServiceConfig pollingServiceConfig = {
            queueReceiver: self.queueReceiver,
            queueName: queueName,
            httpClient: self.httpClient,
            httpEP: processorConfig.HTTPEndpoint,
            deactivateOnFail: processorConfig.deactivateOnFail,
            onMessagePollingFail: onMessagePollingFail(self),
            handleResponse: handleResponse 
        };

        Client? dlcStore = processorConfig["DLCStore"];
        if (dlcStore is Client) {
            pollingServiceConfig.DLCStore = dlcStore;
        }

        int[]? retryHTTPCodes = processorConfig["retryHTTPStatusCodes"];
        if(retryHTTPCodes is int[]) {
            pollingServiceConfig.retryHTTPCodes = retryHTTPCodes;
        }

        //attach the task work
        var assignmentResult = self.messageForwardingTask.attach(messageForwardingService,  attachment = pollingServiceConfig); 
        if(assignmentResult is error) {
            //return error as assigning service to the task failed 
        }  
    }

    public function start() returns error? {
        check self.messageForwardingTask.start();    
    }

    public function stop() returns error? {
        check self.messageForwardingTask.stop();
    }

    function initializeHTTPClient(ForwardingProcessorConfiguration processorConfig) returns http:Client|error {
        http:Client backendClientEP = new(processorConfig.HTTPEndpoint, config = {

            retryConfig: {
                interval: processorConfig.retryInterval, //Retry interval in milliseconds
                count: processorConfig.maxRedeliveryAttempts,   //Number of retry attempts before giving up
                backOffFactor: 1.0, //Multiplier of the retry interval
                maxWaitInterval: 20000,  //Maximum time of the retry interval in milliseconds
                statusCodes: processorConfig.retryHTTPStatusCodes //HTTP response status codes which are considered as failures
            },
            timeoutMillis: 2000
        });
        return backendClientEP;
    }

    function cleanUpJMSObjects() returns error? {
        check self.queueReceiver.__stop();
        //TODO: Ballerina has no method to close session
        //TODO: Ballerina has no method to close connection 
        self.jmsConnection.stop();
    }

    function retryToConnectBroker(ForwardingProcessorConfiguration processorConfig) {
            MessageStoreConfiguration storeConfig = processorConfig.storeConfig;
            int retryCount = 0;
            while(true) {
                var consumerInitResult = initializeConsumer(storeConfig);
                if(consumerInitResult is error) {
                    log:printError("Error while re-connecting to queue " 
                        + storeConfig.queueName + " retry count = " + retryCount, err = ());
                    retryCount = retryCount + 1;
                    int retryDelay = math:round(processorConfig.storeConnectionAttemptInterval *
                                     processorConfig.storeConnectionBackOffFactor);
                    if(retryDelay > processorConfig.maxStoreConnectionAttemptInterval) {
                        retryDelay = processorConfig.maxStoreConnectionAttemptInterval;
                    }
                    runtime:sleep(retryDelay * 1000);
                } else {
                    (self.jmsConnection, self.jmsSession, self.queueReceiver) = consumerInitResult; 
                    break; 
                }
            }
    }
};


function initializeConsumer(MessageStoreConfiguration storeConfig) returns
 (jms:Connection, jms:Session, jms:QueueReceiver) | error {

    string initialContextFactory = getInitialContextFactory(storeConfig.messageBroker);
    string acknowledgementMode = "CLIENT_ACKNOWLEDGE";
    string queueName = storeConfig.queueName;

    // This initializes a JMS connection with the provider.
    jms:Connection jmsConnection = new({
        initialContextFactory: initialContextFactory,
        providerUrl: storeConfig.providerUrl});

    // This initializes a JMS session on top of the created connection.
    jms:Session jmsSession = new(jmsConnection, {
            acknowledgementMode: acknowledgementMode
        });

    // This initializes a queue receiver.
    jms:QueueReceiver queueReceiver = new(jmsSession, queueName = queueName);

    (jms:Connection, jms:Session, jms:QueueReceiver) brokerConnection = (jmsConnection, jmsSession, queueReceiver);
    
    return brokerConnection;
}

function onMessagePollingFail(MessageForwardingProcessor processor) returns function () {
    return function () {
            var cleanupResult = processor.cleanUpJMSObjects();
            if(cleanupResult is error) {
                log:printError("Error while cleaning up jms connection", err = ());
                //we need stop the polling here
            }
            processor.retryToConnectBroker(processor.processorConfig);
    };
}


public type ForwardingProcessorConfiguration record {
    MessageStoreConfiguration storeConfig;
    string HTTPEndpoint;

    //configured in milliseconds for polling interval
    //can specify a cron instead 
    int|string pollTimeConfig;   

    //forwarding retry 
    int retryInterval;      //configured in milliseconds 
    int[] retryHTTPStatusCodes?;
    int maxRedeliveryAttempts;
    
    //connection retry 
    //TODO: make these optional with defaults
    int maxStoreConnectionAttemptInterval = 60;  //configured ins econds 
    int storeConnectionAttemptInterval = 5;     //configured in seconds 
    float storeConnectionBackOffFactor = 1.2;     //configured ins econds 

    //specify message store client to forward failing messages
    Client DLCStore?;
    //specify if processor should deactivate on forwading failure
    boolean deactivateOnFail = false;

};

public type PollingServiceConfig record {
    jms:QueueReceiver queueReceiver;
    string queueName;
    http:Client httpClient; 
    string httpEP;
    Client DLCStore?;
    boolean deactivateOnFail;
    int[] retryHTTPCodes?;
    function () onMessagePollingFail; 
    function (http:Response resp) handleResponse; 
};

