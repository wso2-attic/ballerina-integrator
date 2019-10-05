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

import ballerina/config;
import ballerina/log;
import ballerina/task;
import ballerinax/java.jdbc;
import wso2/sfdc46;

// Salesforce configuration.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("SF_BASE_URL"),
    clientConfig: {
        accessToken: config:getAsString("SF_ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("SF_CLIENT_ID"),
            clientSecret: config:getAsString("SF_CLIENT_SECRET"),
            refreshToken: config:getAsString("SF_REFRESH_TOKEN"),
            refreshUrl: config:getAsString("SF_REFRESH_URL")
        }
    }
};

// MySQL configuration.
jdbc:Client contactsDB = new ({
    url: config:getAsString("JDBC_URL"),
    username: config:getAsString("DB_USERNAME"),
    password: config:getAsString("DB_PASSWORD"),
    poolOptions: {maximumPoolSize: 5},
    dbOptions: {useSSL: false}
});

// Represents `contacts` table.
type Contact record {
    string email;
    string first_name;
    string last_name;
};

// Create salesforce client.
sfdc46:Client salesforceClient = new (sfConfig);

public function main() returns error? {
    task:Scheduler timer = new ({
        intervalInMillis: config:getAsInt("SCHEDULER_INTERVAL_IN_MILLIS"),
        initialDelayInMillis: 0
    });

    // Attach the service to the scheduler.
    var attachResult = timer.attach(sfdcToMysqlService);
    if (attachResult is error) {
        log:printError("Error attaching the sfdcToMysqlService.", attachResult);
        return;
    }

    // Start the scheduler.
    var startResult = timer.start();
    if (startResult is error) {
        log:printError("Starting the task is failed.", startResult);
        return;
    }
}

service sfdcToMysqlService = service {
    resource function onTrigger() returns error? {
        log:printInfo("service started...");
        sfdc46:SoqlRecord[] newSfContacts = check getNewSfContacts();
        if (updateDb(newSfContacts)) {
            log:printInfo("Batch job SFDC -> MySQL has been completed.");
        } else {
            log:printError("Batch job SFDC -> MySQL has been failed!");
        }
    }
};

function getNewSfContacts() returns @tainted sfdc46:SoqlRecord[]|error {
    string q = "SELECT Email, FirstName, LastName, LastModifiedDate FROM Contact WHERE LastModifiedDate > YESTERDAY";
    sfdc46:SoqlResult queryResult = check salesforceClient->getQueryResult(q);
    
    if (queryResult.done == true) {
        return queryResult.records;
    } else {
        return error("Query failed!");
    }
}

function updateDb(sfdc46:SoqlRecord[] newSfContacts) returns boolean {
    foreach sfdc46:SoqlRecord newSfContact in newSfContacts {
        // Query DB and select contacts using the `email`.
        string q = "SELECT first_name, last_name, email FROM contacts WHERE email=?";
        table<Contact> | error dbRes = contactsDB->select(<@untainted> q, Contact, newSfContact["Email"].toString());

        if (dbRes is table<Contact>) {
            if (dbRes.hasNext()) {
                // Update the contact.
                if (updateContact(newSfContact)) {
                    log:printDebug("DB contact updated successfully!");
                } else {
                    log:printError("DB update failed, newSfContact:" + newSfContact.toString());
                }
            } else {
                // Inserting to the DB, since this is a new salesforce account.
                if (insertToDb(newSfContact)) {
                    log:printDebug("New salesforce contact inserted to DB successfully!");
                } else {
                    log:printError("DB Insertion failed, newSfContact:" + newSfContact.toString());
                }
            }
            dbRes.close();
        } else {
            log:printError("Select data from student table failed: " + <string> dbRes.detail()["message"], dbRes);
            return false;
        }
    }
    return true;
}

function insertToDb(sfdc46:SoqlRecord c) returns boolean {
    string q = "INSERT INTO contacts (first_name, last_name, email) VALUES (?,?,?)";
    return handleUpdate(q, c);
}

function updateContact(sfdc46:SoqlRecord c) returns boolean {
    string q = "UPDATE contacts SET first_name=?, last_name=? WHERE email=?";
    return handleUpdate(q, c);
}

function handleUpdate(string q, sfdc46:SoqlRecord c) returns boolean {
    jdbc:UpdateResult | jdbc:Error updateResult =
    contactsDB->update(q, c["FirstName"].toString(), c["LastName"].toString(), c["Email"].toString());

    if (updateResult is jdbc:UpdateResult) {
        return updateResult.updatedRowCount == 1;
    } else {
        log:printError("DB update failed: " + <string> updateResult.detail()["message"], updateResult);
        return false;
    }
}
