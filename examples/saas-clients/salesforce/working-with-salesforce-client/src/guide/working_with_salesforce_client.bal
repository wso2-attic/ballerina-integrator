//
// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
//

import sfdc46;
import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;

// Create Salesforce client configuration by reading from config file.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            refreshUrl: config:getAsString("REFRESH_URL")
        }
    }
};

// Create salesforce client.
sfdc46:Client sfClient = new (sfConfig);

// Constants for error codes and messages.
const string ERROR_CODE = "Sample Error";
const string INVALID_PAYLOAD_MSG = "Invalid request payload";
const string RESPOND_ERROR_MSG = "Error in responding to client.";
const string PAYLOAD_EXTRACTION_ERROR_MSG = "Error while extracting the payload from request.";
const string ACCOUNT_CREATION_ERROR_MSG = "Error while creating Account on Salesforce.";
const string CONTACT_CREATION_ERROR_MSG = "Error while creating Contact on Salesforce.";
const string OPPORTUNITY_CREATION_ERROR_MSG = "Error while creating Opportunity on Salesforce.";

@http:ServiceConfig {
    basePath: "/salesforce"
}
service salesforceService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createAccount"
    }
    // Function to create a Account record.
    resource function createAccount(http:Caller caller, http:Request request) {
        // Define new response.
        http:Response backendResponse = new ();
        json | error payload = request.getJsonPayload();

        if (payload is json) {
            // Get `Account` record.
            json accountRecord = getAccountRecord(caller, payload);
            // Get `Conatcts` from request payload.
            json | error contacts = payload.Contacts;
            // Get `Opportunities` from request payload.
            json | error opportunities = payload.Opportunities;

            if (contacts is error) {
                createAndSendErrorResponse(caller, "Invalid payload, No such column 'Contacts'", "Invalid payload");                
            } else if (opportunities is error) {
                createAndSendErrorResponse(caller, "Invalid payload, No such column 'Opportunities'", 
                "Invalid payload");                
            } else {
                json[] contactsArr = <json[]> contacts;
                json[] opportunitiesArr = <json[]> opportunities;

                // Invoke createAccount remote function from salesforce client.
                string | sfdc46:SalesforceConnectorError response = sfClient->createAccount(<@untainted>accountRecord);

                if (response is string) {
                    // If there is no error, create Contacts & Opportunities.
                    foreach var contact in contactsArr {

                        map<json>|error contactsMap = map<json>.constructFrom(contact);

                        if (contactsMap is map<json>) {
                            contactsMap["AccountId"] = response;

                            // Invoke createContact remote function from salesforce client.
                            string | sfdc46:SalesforceConnectorError contactResponse = 
                            sfClient->createContact(<@untainted>contactsMap);

                            if (contactResponse is sfdc46:SalesforceConnectorError) {
                                // Send the error response.
                                io:println(contactResponse);
                                createAndSendErrorResponse(caller, contactResponse.salesforceErrors.toString(),
                                CONTACT_CREATION_ERROR_MSG);
                            }
                        } else {
                            // Send the error response.
                            io:println(contactsMap);
                            createAndSendErrorResponse(caller, contactsMap.toString(),
                            "Error while converting contact json to map of json.");
                        } 
                    }

                    foreach var opportunity in opportunitiesArr {
                        map<json>|error opportunityMap = map<json>.constructFrom(opportunity);
                        if (opportunityMap is map<json>) {
                            opportunityMap["AccountId"] = response;

                            // Invoke createOpportunity remote function from salesforce client.
                            string | sfdc46:SalesforceConnectorError opportunityResponse = 
                            sfClient->createOpportunity(<@untainted>opportunityMap);

                            if (opportunityResponse is sfdc46:SalesforceConnectorError) {
                                // Send the error response.
                                io:println(opportunityResponse);
                                createAndSendErrorResponse(caller, opportunityResponse.salesforceErrors.toString(),
                                OPPORTUNITY_CREATION_ERROR_MSG);
                            } 
                        } else {
                            // Send the error response.
                            io:println(opportunityMap);
                            createAndSendErrorResponse(caller, opportunityMap.toString(),
                            "Error while converting opportunity json to map of json.");
                        }
                    }

                    // If there is no error, Send the success response.
                    backendResponse.setTextPayload("Account created successfully with id: " + response);
                    respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
                } else {
                    // Send the error response.
                    io:println(response);
                    createAndSendErrorResponse(caller,response.salesforceErrors.toString(),
                    ACCOUNT_CREATION_ERROR_MSG);
                }
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>payload.reason(), PAYLOAD_EXTRACTION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createContact"
    }
    // Function to create a Contact record.
    resource function createContact(http:Caller caller, http:Request request) {
        // Define new response.
        http:Response backendResponse = new ();
        json | error contactRecord = request.getJsonPayload();
        if (contactRecord is json) {
            // Invoke createContact remote function from salesforce client.
            string | sfdc46:SalesforceConnectorError response = sfClient->createContact(<@untainted>contactRecord);
            if (response is string) {
                json result = {
                    contactId: response
                };
                // If there is no error, Send the success response.
                backendResponse.setJsonPayload(result, contentType = "application/json");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            } else {
                // Send the error response.
                io:println(response);
                createAndSendErrorResponse(caller,response.salesforceErrors.toString(),
                CONTACT_CREATION_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>contactRecord.reason(), PAYLOAD_EXTRACTION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createOpportunity"
    }
    // Function to create a Opportunity record.
    resource function createOpportunity(http:Caller caller, http:Request request) {
        // Define new response.
        http:Response backendResponse = new ();
        json | error opportunityRecord = request.getJsonPayload();
        if (opportunityRecord is json) {
            // Invoke createOpportunity remote function from salesforce client.
            string | sfdc46:SalesforceConnectorError response = sfClient->createOpportunity(<@untainted>opportunityRecord);
            if (response is string) {
                json result = {
                    opportunityId: response
                };
                // If there is no error, Send the success response.
                backendResponse.setJsonPayload(result, contentType = "application/json");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            } else {
                // Send the error response.
                io:println(response);
                createAndSendErrorResponse(caller,response.salesforceErrors.toString(),
                OPPORTUNITY_CREATION_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>opportunityRecord.reason(), PAYLOAD_EXTRACTION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/executeQuery"
    }
    // Executes the specified SOQL query.
    resource function executeQuery(http:Caller caller, http:Request request) {
        // Define new response.
        http:Response backendResponse = new ();
        string | error queryRecieved = request.getTextPayload();

        if (queryRecieved is string) {
            // Invoke getQueryResult remote function from salesforce client.
            json | sfdc46:SalesforceConnectorError response = sfClient->getQueryResult(<@untainted>queryRecieved);
            if (response is json) {
                // If there is no error, Send the success response.
                backendResponse.setJsonPayload(response, contentType = "application/json");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            } else {
                // Send the error response.
                io:println(response);
                createAndSendErrorResponse(caller,response.salesforceErrors.toString(),
                "Error occerred while executing a query on salesforce.");
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>queryRecieved.reason(), PAYLOAD_EXTRACTION_ERROR_MSG);
        }
    }
}

// Function to create the error response.
function createAndSendErrorResponse(http:Caller caller, string errorMessage, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code.
    response.statusCode = 500;
    //Set the error message to the error response payload.
    response.setPayload(<string>errorMessage);
    respondAndHandleError(caller, response, respondErrorMsg);
}

// Function to send the response back to the client and handle the error.
function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    // Send response to the caller.
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}

function getAccountRecord(http:Caller caller, json reqPayload) returns json {
    string | error name = reqPayload.Name.toString();
    string | error billingCity = reqPayload.BillingCity.toString();
    string | error website = reqPayload.Website.toString();
    if (name is error) {
        createAndSendErrorResponse(caller, "Invalid payload, No such column 'Name'", "Invalid payload");
    } else if (billingCity is error) {
        createAndSendErrorResponse(caller, "Invalid payload, No such column 'BillingCity'", "Invalid payload");
    } else if (website is error) {
        createAndSendErrorResponse(caller, "Invalid payload, No such column 'Website'", "Invalid payload");
    } else {
        json account = {
            Name: name,
            BillingCity: billingCity,
            Website: website
        };
        return account;
    }
}
