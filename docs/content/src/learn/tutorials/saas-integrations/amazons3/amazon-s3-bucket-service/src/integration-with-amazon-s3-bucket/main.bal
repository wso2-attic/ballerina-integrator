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

import wso2/amazons3;

// Constants for error codes and messages.
const string RESPOND_ERROR_MSG = "Error in responding to client.";
const string CLIENT_CREATION_ERROR_MSG = "Error while creating the AmazonS3 client.";
const string BUCKET_CREATION_ERROR_MSG = "Error while creating bucket on Amazon S3.";
const string BUCKETS_RETRIEVING_ERROR_MSG = "Error while listing buckets on Amazon S3";
const string PAYLOAD_CONVERTION_ERROR_MSG = "Error occured while converting bucket list to json";
const string BUCKET_DELETION_ERROR_MSG = "Error while deleting bucket from Amazon S3.";

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
service amazonS3Service on new http:Listener(9091) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/imageStore/{bucketName}"
    }
    // Function to create a new bucket.
    resource function createBucket(http:Caller caller, http:Request request, string bucketName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            // Invoke createBucket remote function from amazonS3Client.
            amazons3:ConnectorError? response = s3Client->createBucket(<@untainted> bucketName);
            if (response is amazons3:ConnectorError) {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                BUCKET_CREATION_ERROR_MSG);
            } else {
                // If there is no error, then bucket created successfully. Send the success response.
                string textPayload = bucketName + " created on Amazon S3.";
                backendResponse.setTextPayload(textPayload, contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/imageStore"
    }
    // Function to list buckets.
    resource function listBuckets(http:Caller caller, http:Request request) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            // Invoke listBuckets remote function from amazonS3Client.
            var response = s3Client->listBuckets();
            if (response is amazons3:ConnectorError) {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                BUCKETS_RETRIEVING_ERROR_MSG);
            } else {
                // If there is no error, then bucket list retrieved successfully. Send the bucket list.
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
        path: "/imageStore/{bucketName}"
    }

// Function to delete bucket.
    resource function deleteBucket(http:Caller caller, http:Request request, string bucketName) {
        // Assign amazonS3Client global variable to a local variable
        amazons3:AmazonS3Client|amazons3:ConnectorError s3Client = amazonS3Client;
        if (s3Client is amazons3:AmazonS3Client) {
            // Define new response.
            http:Response backendResponse = new();
            // Invoke deleteBucket remote function from amazonS3Client.
            amazons3:ConnectorError? response = s3Client->deleteBucket(<@untainted> bucketName);
            if (response is amazons3:ConnectorError) {
                // Send the error response.
                createAndSendErrorResponse(caller, <@untainted> <string>response.detail()?.message,
                                        BUCKET_DELETION_ERROR_MSG);
            } else {
                // If there is no error, then bucket deleted successfully. Send the success response.
                backendResponse.setTextPayload(<@untainted> string `${bucketName} deleted from Amazon S3.`,
                                        contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            // Send the error response.
            createAndSendErrorResponse(caller, <string>s3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
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
