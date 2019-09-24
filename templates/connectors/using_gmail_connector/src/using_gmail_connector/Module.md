# Working with Gmail Connector

Ballerina Gmail Connector provides the capability to send, read and delete emails through the Gmail REST API. It also provides the ability to read, trash, untrash and delete threads, ability to get the Gmail profile and mailbox history, etc. while handling OAuth 2.0 authentication. This template demonstrates send, read and delete functionalities of the connector.

Please use the module documentation [Ballerina Gmail Connector](https://github.com/wso2-ballerina/module-gmail) for a more detailed explanation.

## Compatibility
| Ballerina Language Version  | Gmail API Version |
|:---------------------------:|:------------------------------:|
|  1.0.0                     |   v1                           |

## Running the Template
Configure the ballerina.conf file inside `src/<module_name>/resources` directory with relevant OAuth authentication configuration and other required values.

Execute the following Ballerina command from within the Ballerina project folder to run the gmail connector template module.
```ballerina    
ballerina run <module_name> --b7a.config.file=<path_to_ballerina.conf_file>
```
