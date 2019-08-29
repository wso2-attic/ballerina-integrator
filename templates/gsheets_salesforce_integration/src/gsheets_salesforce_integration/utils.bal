// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// Create a csv row.
function createCsvRow(string[] row, string accountId) returns string {
    string csvRow = "";
    foreach string element in row {
        csvRow = csvRow + element + ",";
    }
    return <@untainted> csvRow + accountId + "\n";
}

// Create json payload which needed to delete contacts from Salesforce.
function createDeleteJson(json[] contacts) returns json {
    json[] deleteContacts = [];
    foreach json contact in contacts {
        json deleteContact = {
            Id: contact.Id.toString()
        };
        deleteContacts[deleteContacts.length()] = deleteContact;
    }
    return <json> deleteContacts;
}
