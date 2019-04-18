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

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerina/mysql;
//import ballerinax/kubernetes;
//import ballerinax/docker;

//Connect the student details table
mysql:Client studentDetailsDB = new({
    host: "localhost",
    port: 3306,
    name: "StudentDetailsDB",
    username: "root",
    password: "",
    dbOptions: { useSSL: false }
});

//Connect the student's results details table
mysql:Client studentResultsDB = new ({
    host: "localhost",
    port: 3306,
    name: "StudentResultsDB",
    username: "root",
    password: "",
    dbOptions: { useSSL: false }
});

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"message_transformation",
//    path:"/"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"contentfilter"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"validate"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"enricher"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"backend"
//}
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/message_transformation_service:v1.0",
//    name:"ballerina-guides-message-transformation-service",
//    baseImage:"ballerina/ballerina-platform:0.991.0",
//    copyFiles:[{target:"/ballerina/runtime/bre/lib",
//        source:"<mysql-connector-path>"}]
//}

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"message_transformation",
//    tag:"v1.0",
//    baseImage:"ballerina/ballerina-platform:0.980.0"
//}
//@docker:CopyFiles {
//    files:[{source:"<mysql-connector-path>",
//        target:"/ballerina/runtime/bre/lib"}]
//}
//
//@docker:Expose {}
//Define listeners for the service endpoints
listener http:Listener contentfilterEP = new(9090);

listener http:Listener claimvalidateEP = new(9094);

listener http:Listener contentenricherEP = new(9092);

listener http:Listener backendEP = new(9093);

//Define endpoints for services
http:Client validatorEP = new("http://localhost:9094/validater");

http:Client enricherEP = new("http://localhost:9092/enricher");

http:Client clientEP = new("http://localhost:9093/backend");


//Define the global variables
json payload1 = "";
json payload2 = "";

service contentfilter on contentfilterEP {
    resource function filter(http:Caller caller, http:Request req) {
        http:Request filteredReq = req;
        var jsonMsg = filteredReq.getJsonPayload();

        if (jsonMsg is json) {
            http:Response res = new;
            if (!checkForValidData(jsonMsg, res)) {
                respondAndHandleError(caller, res, "Error sending response");
            } else {
                //Assign user input values to variables
                int IdValue = checkpanic int.convert(jsonMsg["id"]);
                string nameString = checkpanic string.convert(jsonMsg["name"]);
                string cityString = checkpanic string.convert(jsonMsg["city"]);
                string genderString = checkpanic string.convert(jsonMsg["gender"]);
                //Add values to the student details table
                var ret = studentDetailsDB->update(
                        "INSERT INTO StudentDetails(id, name, city, gender) values (?, ?, ?, ?)", IdValue,
                        nameString, cityString, genderString);
                handleUpdate(ret, "Add details to the table");
                json iddetails = { id: IdValue };
                //Set filtered payload to the request
                filteredReq.setJsonPayload(untaint iddetails);
                //Forward request to the nesxt ID validating service
                var clientResponse = validatorEP->forward("/validate", filteredReq);
                forwardResponse(caller, clientResponse);
            }
        } else {
            createAndSendErrorResponse(caller, untaint jsonMsg, "Error while content reading");
        }
    }
}

service validater on claimvalidateEP {
    resource function validate(http:Caller caller, http:Request filteredReq) {
        http:Request validatededReq = filteredReq;
        //Get the payload in the request (Student ID)
        var jsonMsg = filteredReq.getJsonPayload();
        if (jsonMsg is json) {
            int idValue = <int>jsonMsg["id"];
            //validate the student's ID
            //In this example student's ID should be in between 100 to 110
            if (100 <= idValue && idValue <= 110) {
                //Print the validity
                log:printInfo("The  Student ID is successfully validated");
                //Forward the request to the enricher service
                var clientResponse = enricherEP->forward("/enrich", validatededReq);
                forwardResponse(caller, clientResponse);
            } else {
                error err = error("Student ID: " + idValue + " is not found");
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.reason());
                respondAndHandleError(caller, res, "Error sending response");
            }
        } else {
            createAndSendErrorResponse(caller, untaint jsonMsg, "Error while content reading");
        }
    }
}

//The content enricher service
service enricher on contentenricherEP {
    resource function enrich(http:Caller caller, http:Request validatedReq) {
        http:Request enrichedReq = validatedReq;
        var jsonMsg = validatedReq.getJsonPayload();
        if (jsonMsg is json) {
            //Get the student's ID value
            int idvalue = <int>jsonMsg["id"];
            //Select details from the data table according to the student's ID
            var selectRet = studentDetailsDB->select("SELECT * FROM StudentDetails", ());
            payload1 = untaint convertTableToJson(selectRet, "Select data from StudentDetails table failed", "Error in student table to json conversion");
            //Select student's results from the student results data table, according to the student's ID
            var selectRet1 = studentResultsDB->select(
                    "select Com_Maths,Physics,Chemistry from StudentResults where ID = ?", (), idvalue);
            payload2 = untaint convertTableToJson(selectRet1, "Select data from StudentResults table failed", "Error in StudentDetails table to json conversion");

            //Define new json variable
            json pay = payload1[0];
            //Add extra values to the jason payload
            pay.fname = pay.name;
            //remove values from the jason payload
            pay.remove("name");
            //Add results to the same payload
            pay.results = payload2[0];
            //Set enriched payload to the request
            enrichedReq.setJsonPayload(pay);
        } else {
            createAndSendErrorResponse(caller, untaint jsonMsg, "Error sending response");
        }

        //Forward enriched request to the client endpoint
        var clientResponse = clientEP->forward("/backend", enrichedReq);
        forwardResponse(caller, clientResponse);
    }
}

service backend on backendEP {
    resource function backend(http:Caller caller, http:Request enrichedReq) {
        //Get the requset payload
        var jsonMsg = enrichedReq.getJsonPayload();
        if (jsonMsg is json) {
            //Send payload as response
            http:Response res = new;
            res.setJsonPayload(untaint jsonMsg);
            respondAndHandleError(caller, res, "Error sending response");
        } else {
            createAndSendErrorResponse(caller, untaint jsonMsg, "Error sending response");
        }
    }
}

function forwardResponse(http:Caller caller, http:Response|error forwardingResponse) {
    if (forwardingResponse is http:Response) {
        respondAndHandleError(caller, forwardingResponse, "Error sending response");
    } else {
        createAndSendErrorResponse(caller, forwardingResponse, "Error sending response");
    }
}

function createAndSendErrorResponse(http:Caller caller, error sourceError, string respondErrorMsg) {
    http:Response response = new;
    response.statusCode = 500;
    response.setPayload(<string> sourceError.detail().message);
    respondAndHandleError(caller, response, respondErrorMsg);
}

function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    var respondRet = caller->respond(response);
    if (respondRet is error) {
        log:printError(respondErrorMsg, err = respondRet);
    }
}

function convertTableToJson(table<record{}>|error tableOrError, string dataRetrievalErrorMsg, string conversionErrorMsg) returns json? {
    if (tableOrError is table<record{}>) {
        json | error convertedJson = json.convert(tableOrError);
        if (convertedJson is json) {
            return convertedJson;
        } else {
            log:printError(conversionErrorMsg, err = convertedJson);
        }
    } else {
        log:printError(dataRetrievalErrorMsg, err = tableOrError);
    }
}

//Function to handle the user input
function checkForValidData(json msg, http:Response res) returns boolean {
    error? err = ();
    //Check input through the regular expressions
    if (!(checkpanic msg.id.toString().matches("\\d+"))) {
        err = createError("student ID containts invalid data");
    } else if (!(checkpanic msg.name.toString().matches("[a-zA-Z]+"))) {
        err = createError("student Name containts invalid data");
    } else if (!(checkpanic msg.city.toString().matches("^[a-zA-Z]+([\\-\\s]?[a-zA-Z0-9]+)*$"))) {
        err = createError("student city containts invalid data");
    } else if (!(checkpanic msg.gender.toString().matches("[a-zA-Z]+"))) {
        err = createError("student gender containts invalid data");
    }
    if (err is error) {
        res.statusCode = 400;
        res.setPayload(<string> (err.detail().message));
        return false;
    } else {
        return true;
    }
}

function createError(string message) returns error {
    return error(message);
}

function handleUpdate(sql:UpdateResult|error returned, string message) {
    if (returned is sql:UpdateResult) {
        log:printInfo(message + " status: " + returned.updatedRowCount);
    } else {
        log:printInfo(message + " failed: " + <string>returned.detail().message);
    }
}

