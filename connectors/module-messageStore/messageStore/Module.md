Provides guaranteed delivery for messaging in Ballerina

# Compatibility

|                    |    Version     |  
|:------------------:|:--------------:|
| Ballerina Language |   0.991.0      |

# Module overview

`messageStore` connector allows you to perform

1. Decouple message producer and subscriber
2. Enable guaranteed message delivery to an HTTP endpoint
3. Message rate throttling 
4. In order message delivery 
5. Scheduled message delivery 

# Design

`messageStore` connector users `JMS connector` and `HTTP connector` underneath. It has two main components. 

* `messageStore:Client` is used to store messages. The messages are stored into a queue of a message broker. 
* `messageStore:MessageForwardingProcessor` is used to poll messages from the store (i.e queue in message broker), and 
forward them reliably to HTTP endpoint. 

HTTP connector has resiliency configurations (max retry attempts, retry interval etc.). In order to obtain reliable message 
forwarding, `messageStore` connector makes use of resiliency provided by HTTP Client of Ballerina. In case of a failure case,
we need to keep the message in the queue. Hence, as the acknowledgement mode the `messageStore:MessageForwardingProcessor` component
uses `CLIENT ACKNOWLEDGE` when polling message. Only if the message forwarding is successful, the JMS message is acknowledged. 

Before storing the inbound HTTP message into the message broker queue, we need to convert the HTTP message into a JMS message. 
At the same time, we need to ensure we capture all information in the HTTP message. (JMS Map message)[https://docs.oracle.com/javaee/6/api/javax/jms/MapMessage.html] is used as the JMS message type in the design. The header names and values are converted to map entries. 
The payload is also stored as a field in the map message using `byte[]` as the value. The idea is that the connector does
not try to interpret the message when storing it as a JMS message. This makes reconstruction of HTTP message at `MessageForwardingProcessor`
straightforward. 

`MessageForwardingProcessor` uses `Task` in Ballerina to trigger message polling. This enables to poll messages by interval 
or by cron expression. 

To forward messages to HTTP endpoint configured, the connector uses Ballerina http client. The configuration of `MessageForwardingProcessor`
is capable of absorbing any configuration for HTTP client of Ballerina. This enables to forward messages to secured HTTP service
and many other features bundled into HTTP client. 

Both `Client` and `MessageForwardingProcessor` components have resiliency for connecting to message broker. If it lost 
connection to the broker, both can recover automatically. 

# Features

## Storing messages

### 1. Configure any message broker

This is possible as the connector uses `JMS` connector underneath. It supports any message broker with `JMS` support. 
Users need to place third party .jar files into `<BALLERINA_HOME>/bre/lib` directory. Currently, it is tested with 
Active MQ, IBM MQ and WSO2 MB. 

### 2. Store messages reliably

If storing a message failed, the connector will try to store it to the same message store a few times before giving up. 
The store connector will try to re-initialize the connection to the broker and retry to send the message over JMS. If this is a transient connection issue  while storing the message, this feature can recover from that situation. 

When retrying, users can configure

* interval - (seconds) this is the interval retrying will start
* backOffFactor - interval of retrying will increase per iteration by this factor
* maxWaitInterval - (seconds) maximum wait interval retrying can increase to
* count - Specify (-1) to retry infinitely. Otherwise, this will be the maximum number of retries

If failed to store the message after all retries `store` method will return an error.
 
### 3. Configure a secondary message store

If all retries to store the message to the primary store has failed and if a secondary store is configured store connector will try to store it in the secondary store. This can be a separate queue of the same broker. However, 
configuring a queue of a different broker instance will give more reliability in case of primary broker is not responding.
Secondary store can also have resiliency parameters. 

If failed to store the message after all retries to primary store and secondary store, `store` method will return an error.

>NOTE: you can have another `secondary` store for the configured secondary store as well. This will build a chain of stores
to retry storing. 

### 4. Store messages using a secured connection to the message broker 

Not available

### 5. Fail-over of brokers

JMS broker have fail-over feature. That is, if primary broker is not reachable, JMS implementation will try the next broker
in the fail-over chain. As the connector uses JMS, this feature is inherited. 

Example: https://activemq.apache.org/failover-transport-reference
         https://docs.wso2.com/display/MB320/Handling+Failover 

## Forwarding messages

### 1. Forwarding messages to HTTP services. Configure SSL, timeouts, keep-alive, chunking etc 

The `MessageForwardingProcessor` can be configured to invoke secured services using SSL/TLS or Oauth tokens. In fact, 
any configuration related to (HTTP Client of Ballerina)[https://ballerina.io/learn/api-docs/ballerina/http.html#ClientEndpointConfig] can be provided. 

Example config: 

```ballerina

    http:ServiceEndpointConfiguration endpointConfig = {
        secureSocket: {
            trustStore: {
                path: "${ballerina.home}/bre/security/trustStore",
                password: "ballerina"
            }
        },
        timeoutMillis: 70000
    };
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        HttpOperation: http:HTTP_POST,
        HttpEndpointConfig: endpointConfig
        ...
    };
```

### 2. Resiliency in forwarding messages to HTTP service

When forwarding messages, user can configure

* retryInterval - (milliseconds) interval between two retries
* maxRedeliveryAttempts - maximum number of times to retry

Note that if `maxRedeliveryAttempts` breached when trying to forward a message, that message is considered as a forwarding fail message.
According to `forwardingFailAction` this message will be either dropped or routed to another store. Also if you configured `retryConfig`
under httpClient config set at `HttpEndpointConfig`, it will be overridden by these values. 

Sample config : retry 5 times with 3 second interval 

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0/2 * * * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5
    };
```

### 3. Control message forwarding rate

Message forwarding rate is controlled by following parameters

* pollTimeConfig - users can configure an interval where forwarding task triggers. Even a cron expression is possible. (i.e `0/2 * * * * ?`)
* forwardingInterval - By default this is configured to`0`. It is effective only when `batchSize > 1`. The messages in a 
                       batch will be forwarded to the HTTP service with a delay of `forwardingInterval` between the messages configured in milliseconds. By default `batchSize = 1`. 

>Note : message preprocess delay and response handling delay will also get added and affect to the overall forwarding rate. This is because 
        messages are processed one after the other. 

Sample config: Forward a message once two seconds

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0/2 * * * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5
    };
```

Sample config: Forward a message once 100ms

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: 100,
        retryInterval: 3000,
        maxRedeliveryAttempts: 5
    };
```

### 4. Scheduled message forwarding

When you need to trigger message forwarding at a specific time of the day, or at a specific
time every day, every week, you can specify a cron. 

There is a question how many messages to process once forwarding triggered because there can be 
millions of messages on the store. You can specify that by `batchSize` (default = 1). The interval between 
two message forwards is configured by `forwardingInterval` (default = 0). 

>Note: When `batchSize` is configured to -1 the processor will poll messages until the store becomes empty. When there is
       no messages in store, processing will get stopped until next time it is triggered as per the cron specified.

On how to construct cron expressions, refer (here)[http://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html]. 

Sample config: Trigger at 3.45 P.M everyday and forward all messages on store, one message per 3 seconds. 

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0 45 15 * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5,
        batchSize: -1,
        forwardingInterval: 3000
    };

```

Sample config: Fire every minute starting at 2pm and ending at 2:59pm, every day. Every minute forward 30 messages max with an interval
               of one second between each message forward. 

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0 * 14 * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5,
        batchSize: 30,
        forwardingInterval: 1000
    };
```

### 5. Consider responses with configured HTTP status codes as forwarding failures

Sometimes, even if the backend HTTP service sent a response, we need to consider it as a failure. For an example, if
HTTP status code is 500 or 404, it is in fact not processed by the service. To cater the cases, you can specify a set of
status codes which message processor should consider as a forwarding failure, and hence retry to forward again. 

Sample config; 

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0/2 * * * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5,
        retryHttpStatusCodes:[500,400]
    };
```

### 6. Different actions upon a message forwarding failure

Depending on the use-case, uses will need to do either of following when message processor failed to forward it to the
HTTP service. 

* DROP - drop the message and continue with the next message on the store
* DEACTIVATE - stop message processing further. User will need to manually remove 
               the message or fix the issue and restart message polling service. 
* DLC_STORE - move the failing message to a configured message store and continue with the next message. Later user can 
             deal with the messages in the DLC store manually. 

By default, the behavior is to DROP. 

Sample config: Try to forward each message 5 times. If there is a failure, deactivate the processor. 

```ballerina
    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0/2 * * * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5,
        forwardingFailAction: messageStore:DEACTIVATE
    };
```

### 7. Ability to configure a Dead Letter Store

Dead Letter Store is a pattern where the message processing will set aside the messages those failed to store. Those messages
are moved to a separate store and the user can deal with them manually later. 

Sample config: Try to forward each message 5 times. If there is a failure, move the message to queue `myDLCStore`. 

```Ballerina
    messageStore:MessageStoreConfiguration dlcMessageStoreConfig = {
        messageBroker: "ACTIVE_MQ",
        providerUrl: "tcp://localhost:61616",
        queueName: "myDLCStore"
    };

    messageStore:Client dlcStoreClient = new messageStore:Client(dlcMessageStoreConfig);

    messageStore:ForwardingProcessorConfiguration myProcessorConfig = {
        storeConfig: myMessageStoreConfig,
        HttpEndpointUrl: "http://127.0.0.1:9095/testservice/test",
        pollTimeConfig: "0/2 * * * * ?",
        retryInterval: 3000,
        maxRedeliveryAttempts: 5,
        forwardingFailAction: messageStore:DLC_STORE,
        DLCStore: dlcStoreClient 
    };
```

### 8. Pre-process message before forwarding to the backend service

By design message processor will reconstruct the HTTP request that is stored in the message store and forward to the service.
However, sometimes there is a requirement to modify the HTTP request before sending it out to a HTTP service (i.e a heavy transformation).
A workaround will be to do the transformation prior to storing the message and store it, but if it is heavy, user might 
want to store what is inbound and do the transformation at message processing with a controlled forwarding rate. 

In such cases, user can define a function with the logic to do the pre-processing and configure it as follows.

```ballerina
function preProcessRequestFunction(http:Request request) {
    request.setHeader("company", "WSO2");
}
var myMessageProcessor = new messageStore:MessageForwardingProcessor(myProcessorConfig, 
            handleResponseFromBE, preProcessRequest = preProcessRequestFunction);
...
```

>Note The time taken to pre-process the message will get added to the message forwarding interval. 

### 9. Process response received by backend service after the forward

User need to do some operation on the response received by the backend service. This may be calling
another service with the response, or store details of the response in a database.  User can define a function with the 
logic to handle the response and configure it to the processor.

```ballerina
function handleResponseFromBE(http:Response resp) {
    var payload =  resp.getJsonPayload();
    if(payload is json) {
        log:printInfo("Response received " + "Response status code= "+ resp.statusCode + ": "+ payload.toString());
    } else {
        log:printError("Error while getting response payload ", err=payload);
    }
}
var myMessageProcessor = new messageStore:MessageForwardingProcessor(myProcessorConfig, handleResponseFromBE);
...
```

>Note The time taken to process the response message will get added to the message forwarding interval. 

## Integration patterns 

### 1. Reliable delivery

The connector can be used to forward an HTTP message reliable to a HTTP service. If you need to expose an unreliable HTTP service
in an reliable manner, this connector can be used. Message will not get discarded until it is successfully delivered to the service. 
The poison messages which cannot be processed by the service, can be routed to DLC store and users can manually deal with them. 

### 2. In order message delivery 

This connector stores messages in a queue of a message broker, which keeps FIFO behavior. Hence, the inbound messages are stored
in the order they reached the service. When polling, messages are picked and processed once after the other, where the order
of messages in the queue is kept when delivering to the backend. If a message is failed to process, the processor can be configured
to stop until issue is fixed, so that the order is ensured.

### 3. Message throttling 

Sometimes, there are legacy backend services in the systems, which cannot service inbound requests in a high throughput. they may crash
or go out of resources. If there are spikes in the inbound request rate, which backend service cannot withhold, there is a need to regulate
the message rate. 

Messages can be stored in the incoming rate. Message forwarding rate is governed by following parameters. 

* pollTimeConfig - users can configure an interval where forwarding task triggers. Even a cron expression is possible. (i.e `0/2 * * * * ?`)
* forwardingInterval - By default this is configured to`0`. It is effective only when `batchSize > 1`. The messages in a 
                       batch will be forwarded to the HTTP service with a delay of `forwardingInterval` between the messages configured in milliseconds. By default `batchSize = 1`. 

### 4. Asynchronous messaging 

By design, messages are not processed in a synchronous manner. Inbound messages are stored and then they are processed. Processing can be scheduled 
so that messages came in are processed later in off-peak hours. Storing service and processing service can be two separate containers. 
These are the semantics of asynchronous message processing. Reliable delivery is added on top of it. Thus, in places where asynchronous messaging
is required, this connector can be used. 

## Extensibility

As the connector is using `JMS` connector provided by Ballerina, any message broker with the support for `JMS` can be configured
   for reliable messaging. Users need to place third party .jar files into `<BALLERINA_HOME>/bre/lib` directory. 