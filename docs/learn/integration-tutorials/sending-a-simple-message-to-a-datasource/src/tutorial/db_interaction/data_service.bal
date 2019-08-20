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

import ballerina/http;
import ballerina/log;
import ballerina/config;
import ballerinax/java.jdbc;

jdbc:Client testDB = new({
    url: "jdbc:mysql://MYSQL_DB_HOST:MYSQL_DB_PORT/MYSQL_DB_NAME",
    username: "MYSQL_DB_USERNAME",
    password: "MYSQL_DB_PASSWORD",
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
});

listener http:Listener httpListener = new(9092);

@http:ServiceConfig {
    basePath: "/hospitalMgtService"
}

// RESTful service
service dbTransactionService on httpListener {
    // Resource that handles the HTTP GET requests that are directed to doctors specialized on a specific area using 
    // path '/doctor/<name>'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/doctor/{name}"
    }
    resource function doctorData(http:Caller caller, http:Request req, string name) {

        http:Response response = new;

        json | error doctorData = getDoctorDetails(name);

        if (doctorData is json) {
            response.statusCode = 200;
            response.setJsonPayload(doctorData);
        } else {
            response.statusCode = 500;
            response.setJsonPayload("Error in retrieving data from the database", contentType = "application/json");
        }

        var result = caller->respond(response);

        if (result is error) {
            log:printError("Error sending response to the client", err = result);
        }
    }


    // Resource that handles the HTTP POST requests that are directed to the path '/doctor' to add a new 
    // doctor's information.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/doctor"
    }
    resource function addDoctorData(http:Caller caller, http:Request request) {

        http:Response response = new;

        log:printInfo("Inserting doctors' information");
        
        var requestData = request.getJsonPayload();

        if (requestData is json) {
            string docName = <string> requestData.docName;
            string hospital = <string> requestData.hospital;
            string speciality = <string> requestData.speciality;
            string availability = <string> requestData.availability;
            int charge = <int> requestData.charge;
            string payload = "json";

            var retValue = addDoctorDetails(docName, hospital, speciality, availability, charge);
            
            if (retValue is jdbc:UpdateResult) {
                if (retValue.updatedRowCount > 0) {
                    json msg = "Insert successful";
                    int statusCode = 200;

                   var res = handleUpdate(caller, msg, statusCode, payload);
                } else {
                    json msg = "Insert Failed";
                    int statusCode = 400;

                    var res = handleUpdate(caller,msg, statusCode, payload);
                }
            } else {
                json msg = "Insert Failed due to query execution failure";
                int statusCode = 400;

                var res = handleUpdate(caller,msg, statusCode, payload);
            }
        } else {
            json msg = "Request payload is not json";
            int statusCode = 400;
            string payload = "other"; 
           
            var res = handleUpdate(caller,msg, statusCode, payload);
        }
    }

    // Resource that handles the HTTP PUT requests that are directed to the path '/doctor/<docName>' to update an 
    // existing doctor's information.
    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/doctor/{docName}"
    }
    resource function updateDoctorData(http:Caller caller, http:Request request, string docName) {

        http:Response response = new;

        log:printInfo("Updating Doctors' Information");

        var requestData = request.getJsonPayload();
        
        if (requestData is json) {
            string hospital = <string> requestData.hospital;
            string speciality = <string> requestData.speciality;
            string availability = <string> requestData.availability;
            int charge = <int> requestData.charge;
            string payload = "json";

            var retValue = updateDoctorDetails(docName, hospital, speciality, availability, charge);

            if (retValue is jdbc:UpdateResult) {
                if (retValue.updatedRowCount > 0) {
                    json msg = "Update successful";
                    int statusCode = 200;
                    var res = handleUpdate(caller, msg, statusCode, payload);
                } else {
                    json msg = "Update Failed due to no matching record";
                    int statusCode = 400;

                    var res = handleUpdate(caller, msg, statusCode, payload);
                }
            } else {
                json msg = "Update Failed while query execution";
                int statusCode = 400;

                var res = handleUpdate(caller, msg, statusCode, payload);
            }      
        } else {
            json msg = "Payload type does not match";
            int statusCode = 400;
            string payload = "other"; 
        
            var res = handleUpdate(caller, msg, statusCode, payload);
        }
    }

    // Resource that handles the HTTP DELETE requests, which are directed to the path '/doctor/<docName>' to delete 
    //an existing doctor's information.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/doctor/{docName}"
    }
    resource function deleteDoctorData(http:Caller caller, http:Request request, string docName) {

        http:Response response = new;

        log:printInfo("Deleting Doctors' Information");

        var retValue = deleteDoctorDetails(docName);
        string payload = "json";

        if (retValue is jdbc:UpdateResult) {
            if (retValue.updatedRowCount > 0) {
                json msg = "Delete successful";
                int statusCode = 200;
                
                var res = handleUpdate(caller, msg, statusCode, payload);
            } else {
                json msg = "No matching record";
                int statusCode = 400;
                var res = handleUpdate(caller, msg, statusCode, payload);
            }
        } else {
            json msg = "Query execution failed";
            int statusCode = 400;
            var res = handleUpdate(caller, msg, statusCode, payload);
        }
    }
}

function handleUpdate(http:Caller caller,json msg, int statusCode, string payload) returns http:Caller|error? {

    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload(msg, contentType = "application/json");
  
    http:Caller|error? result = caller->respond(response);

   if(payload == "json") {
        if(result is error){
            log:printError("Error in sending the response");     
        }else{
            log:printInfo("Sending the response to client"); 
        }
        return result;
    } else {
        log:printError("Payload mismatch"); 
    }
}

