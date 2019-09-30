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

import ballerina/config;
import ballerina/http;
import ballerina/log;
import wso2/sfdc46;

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
// Create Record Type want to create.
const string CONTACTS = "Contacts";
const string OPPORTUNITIES = "Opportunities";
type RecordType CONTACTS | OPPORTUNITIES;

@http:ServiceConfig {
    basePath: "/salesforce"
}
service salesforceService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/account"
    }
    // Function to create a Account record.
    resource function createAccount(http:Caller caller, http:Request request) returns error? {
        // Define new response.
        http:Response backendResponse = new ();
        json payload = check request.getJsonPayload();
        // Get `Account` record.
        json account = {
            Name: payload.Name.toString(),
            BillingCity: payload.BillingCity.toString(),
            Website: payload.Website.toString()
        };

        // Invoke createAccount remote function from salesforce client.
        string response = check sfClient->createAccount(<@untainted>account);
        // Create Contacts & Opportunities for created Account.
        string[] createdContacts = check createRecords(CONTACTS, <json[]>payload.Contacts, response);
        string[] createdOpportunities = check createRecords(OPPORTUNITIES, <json[]>payload.Opportunities, response);

        json resPayload = { accountId: response, contacts: createdContacts, opportunities: createdOpportunities };
        respondAndHandleError(caller, http:STATUS_OK, <@untainted> resPayload);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/query"
    }
    // Executes the specified SOQL query.
    resource
    function executeQuery(http:Caller caller, http:Request request) returns error? {
        // Define new response.
        http:Response backendResponse = new ();
        string queryRecieved = check request.getTextPayload();
        // Invoke getQueryResult remote function from salesforce client.
        sfdc46:SoqlResult response = check sfClient->getQueryResult(<@untainted>queryRecieved);
        json queryResult = check json.constructFrom(response);
        respondAndHandleError(caller, http:STATUS_OK , <@untainted> queryResult);
    }
}

function createRecords(RecordType recordType, json[] records, string accountId) returns @tainted string[] | error {
    string[] createdRecords = [];
    foreach json rec in records {
        createdRecords[createdRecords.length()] = check createRecord(recordType, rec, accountId);
    }
    return createdRecords;
}

function createRecord(RecordType recordType, json rec, string accountId) returns @tainted string | error {
    map<json> recMap = check map<json>.constructFrom(rec);
    recMap["AccountId"] = accountId;
    if (recordType == CONTACTS) {
        // Invoke createContact remote function from salesforce client.
        return check sfClient->createContact(<@untainted>recMap);
    } else {
        // Invoke createOpportunity remote function from salesforce client.
        return check sfClient->createOpportunity(<@untainted>recMap);
    }
}

// Send the response back to the client and handle responding errors.
function respondAndHandleError(http:Caller caller, int resCode, json | xml | string payload) {
    http:Response res = new;
    res.statusCode = resCode;
    res.setPayload(payload);
    var respond = caller->respond(res);
    if (respond is error) {
        log:printError("Error occurred while responding", err = respond);
    }
}
