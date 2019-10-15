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
import ballerina/http;
import ballerina/log;
import ballerina/stringutils;

import wso2/amazons3;

// Constants for error codes and messages.
const string ERROR_CODE = "Sample Error";
const string RESPOND_ERROR_MSG = "Error in responding to client.";
const string CLIENT_CREATION_ERROR_MSG = "Error while creating the AmazonS3 client.";
const string PAYLOAD_EXTRACTION_ERROR_MSG = "Error while extracting the payload from request.";
const string PAYLOAD_CONVERTION_ERROR_MSG = "Error occured while converting bucket list to json";
const string OBJECT_CREATION_ERROR_MSG = "Error while creating object on Amazon S3.";
const string OBJECTS_RETRIEVING_ERROR_MSG = "Error while listing objects on bucket : ";
const string OBJECT_DELETION_ERROR_MSG = "Error while deleting object from Amazon S3.";
const string INVALID_PAYLOAD_MSG = "Invalid request payload";

// Create Amazons3 client configuration with the above accesskey and secretKey values.
amazons3:ClientConfiguration amazonS3Config = {
    accessKeyId: config:getAsString("ACCESS_KEY_ID"),
    secretAccessKey: config:getAsString("SECRET_ACCESS_KEY"),
    region: config:getAsString("REGION"),
    clientConfig: {
        http1Settings: {chunking: http:CHUNKING_NEVER}
    }
};

// Create AmazonS3 client with the above amazonS3Config.
amazons3:AmazonS3Client|amazons3:ConnectorError amazonS3Client = new(amazonS3Config);

@http:ServiceConfig {
    basePath: "/amazons3"
}

service amazonS3Service on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/imageStore/{bucketName}/{objectName}"
    }
    // Function to create a new object into an existing bucket.
    resource function createObject(http:Caller caller, http:Request request, string bucketName, string objectName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            // Extract the object content from request payload.
            string|xml|json|byte[]|error objectContent = extractRequestContent(request);
            if objectContent is error {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>objectContent.detail()?.message,
                                PAYLOAD_EXTRACTION_ERROR_MSG);
            } else {
                // Invoke createObject remote function from amazonS3Client.
                error? response = s3Client->createObject(<@untainted> bucketName, <@untainted> objectName,
                                                    <@untainted> objectContent);
                if (response is amazons3:ConnectorError) {
                    // Send the error response.
                    createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                    OBJECT_CREATION_ERROR_MSG);
                } else {
                    // If there is no error, then object created successfully. Send the success response.
                    backendResponse.setTextPayload(<@untainted> string `${objectName} created on Amazon S3 bucket : 
                            ${bucketName}.`, contentType = "text/plain");
                    respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
                }
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/imageStore/{bucketName}/{objectName}"
    }
    // Function to get object.
    resource function getObject(http:Caller caller, http:Request request, string bucketName, string objectName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            //Get the response content type from query params.
            string? params = request.getQueryParamValue("responseContentType");
            string responseContentType = <string> params;

            // Invoke getObject remote function from amazonS3Client.
            var response = s3Client->getObject(<@untainted> bucketName, <@untainted> objectName);
            if (response is amazons3:S3Object) {
                // S3Object will be returned on success.
                // Set the object content to the payload with the expected content type.
                backendResponse.setBinaryPayload(<@untainted> <byte[]>response["content"], contentType = <@untainted> responseContentType);
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            } else {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                 "Error while creating object on Amazon S3.");
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }
    
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/imageStore/{bucketName}"
    }
    // Function to list objects.
    resource function listObjects(http:Caller caller, http:Request request, string bucketName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            // Invoke listObjects remote function from amazonS3Client.
            var response = s3Client->listObjects(<@untainted> bucketName);
            if (response is amazons3:ConnectorError) {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                OBJECTS_RETRIEVING_ERROR_MSG + "${bucketName}.");
            } else {
                // If there is no error, then object list retrieved successfully. Send the object list.
                var list = json.constructFrom(response);
                if (list is json) {
                    backendResponse.setJsonPayload(<@untainted> list, contentType = "application/json");
                    respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
                } else {
                    createAndSendErrorResponse(caller, <@untainted> <string>list.detail()?.message,
                                PAYLOAD_CONVERTION_ERROR_MSG);
                }
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/imageStore/{bucketName}/{objectName}"
    }
    // Function to delete object.
    resource function deleteObject(http:Caller caller, http:Request request, string bucketName, string objectName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            amazons3:ConnectorError? response = s3Client->deleteObject(<@untainted> bucketName, <@untainted> objectName);
            if (response is amazons3:ConnectorError) {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                        OBJECT_DELETION_ERROR_MSG);
            } else {
                // If there is no error, then object deleted successfully. Send the success response.
                backendResponse.setTextPayload(<@untainted> string `${objectName} deleted from Amazon S3 bucket : ${bucketName}.`,
                                        contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }
}

// Function to extract the object content from request payload
function extractRequestContent(http:Request request) returns @tainted string|xml|json|byte[]|error {
    string contentTypeStr = request.getContentType();
    if (stringutils:equalsIgnoreCase(contentTypeStr, "application/json")) {
        var jsonObjectContent = request.getJsonPayload();
        if (jsonObjectContent is json) {
            return jsonObjectContent;
        }
    }
    if (stringutils:equalsIgnoreCase(contentTypeStr, "application/xml")) {
        var xmlObjectContent = request.getXmlPayload();
        if (xmlObjectContent is xml) {
            return xmlObjectContent;
        }
    }
    if (stringutils:equalsIgnoreCase(contentTypeStr, "text/plain")) {
        var textObjectContent = request.getTextPayload();
        if (textObjectContent is string) {
            return textObjectContent;
        }
    }
    var binaryObjectContent = request.getBinaryPayload();
    if (binaryObjectContent is byte[]) {
        return binaryObjectContent;
    } else {
        error err = error(ERROR_CODE, message = INVALID_PAYLOAD_MSG);
        return err;
    }
}

// Function to create the error response.
function createAndSendErrorResponse(http:Caller caller, string errorMessage, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code.
    response.statusCode = 500;
    //Set the error message to the error response payload.
    response.setPayload(<string> errorMessage);
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
