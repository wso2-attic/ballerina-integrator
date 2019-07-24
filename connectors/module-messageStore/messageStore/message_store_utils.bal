// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

public type MessageBroker ACTIVE_MQ|IBM_MQ|WSO2MB;

public type MessageForwardFailAction DROP|DLC_STORE|DEACTIVATE;

public const DELETE = "DELETE";

//constants for message forwarding failure actions
public const DROP = "DROP";
public const DLC_STORE = "DLC_STORE";
public const DEACTIVATE = "DEACTIVATE";

//constants for broker types
public const ACTIVE_MQ = "ACTIVE_MQ";
public const IBM_MQ = "IBM_MQ";
public const WSO2MB = "WSO2MB";

//constant used as key for paload in JMS map message
const PAYLOAD = "PAYLOAD";

const string CLIENT_ACKNOWLEDGE = "CLIENT_ACKNOWLEDGE";

// Error Codes
final string MESSAGE_STORE_ERROR_CODE = "(wso2/messageStore)MessageStoreError";

//context factory class name holder
map<string> contextFactoryMapper = {
   "ACTIVE_MQ": "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
   "IBM_MQ" : "com.sun.jndi.fscontext.RefFSContextFactory",
   "WSO2MB" : "org.wso2.andes.jndi.PropertiesFileInitialContextFactory"
};

# Get canonical name of the InitialConnectionFactory class for given broker. 
# 
# + brokerName - `MessageBroker` 
# + return - Name of the InitialConnectionFactory class name as a `string`
function getInitialContextFactory(MessageBroker brokerName) returns string {
    return <string> contextFactoryMapper[brokerName];
}