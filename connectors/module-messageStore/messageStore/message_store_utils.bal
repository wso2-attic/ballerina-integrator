import ballerina/io;

public type MessageBroker ACTIVE_MQ|IBM_MQ|WSO2MB;

//constants 
public const ACTIVE_MQ = "ACTIVE_MQ";
public const IBM_MQ = "IBM_MQ";
public const WSO2MB = "WSO2MB";

public const PAYLOAD = "PAYLOAD";

// Error Codes
final string MESSAGE_STORE_ERROR_CODE = "(wso2/messageStore)MessageStoreError";

map<string> contextFactoryMapper = {
   "ACTIVE_MQ": "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
   "IBM_MQ" : "",
   "WSO2MB" : ""
};

function getInitialContextFactory(MessageBroker brokerName) returns string {
    return <string> contextFactoryMapper[brokerName];
}





