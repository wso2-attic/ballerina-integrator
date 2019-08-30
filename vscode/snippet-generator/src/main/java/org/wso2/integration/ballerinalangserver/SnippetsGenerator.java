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

package org.wso2.integration.ballerinalangserver;

//import integration.ballerinalang.langserver.SnippetsBlock.SnippetType;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.ballerinalang.langserver.common.utils.CommonUtil;

public class SnippetsGenerator {

    private SnippetsGenerator() {
    }

    /**
     * Get Record Definition Snippet Block.
     *
     * @return {@link SnippetsBlock}     Generated Snippet Block
     */
    public static SnippetsBlock getRecordDefinitionSnippet() {
        String snippet = "type ${1:RecordName} record {" + CommonUtil.LINE_SEPARATOR + "\t${2}"
                + CommonUtil.LINE_SEPARATOR + "};";

        return new SnippetsBlock(ItemResolverConstants.RECORD_TYPE, snippet, ItemResolverConstants.SNIPPET_TYPE,
                                SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get HTTP Resource Definition Snippet Block.
     *
     * @return {@link SnippetsBlock}     Generated Snippet Block
     */
    public static SnippetsBlock getHttpResourceDefinitionSnippet() {
        ImmutablePair<String, String> httpImport = new ImmutablePair<>("ballerina", "http");
        String snippet = "resource function ${1:newResource}(http:Caller ${2:caller}, ${3:http:Request request}) {"
                + CommonUtil.LINE_SEPARATOR + "\t${4}" + CommonUtil.LINE_SEPARATOR + "}";
        return new SnippetsBlock(ItemResolverConstants.RESOURCE, snippet, ItemResolverConstants.SNIPPET_TYPE,
                                SnippetsBlock.SnippetType.SNIPPET, httpImport);
    }

    /**
     * Get Service Definition Snippet Block.
     *
     * @return {@link SnippetsBlock}     Generated Snippet Block
     */
    public static SnippetsBlock getServiceDefSnippet() {
        ImmutablePair<String, String> httpImport = new ImmutablePair<>("ballerina", "http");
        String snippet = "service ${1:serviceName} on new http:Listener(8080) {"
                + CommonUtil.LINE_SEPARATOR + "\tresource function ${2:newResource}(http:Caller ${3:caller}, "
                + "http:Request ${5:request}) {" + CommonUtil.LINE_SEPARATOR + "\t\t" + CommonUtil.LINE_SEPARATOR +
                "\t}" + CommonUtil.LINE_SEPARATOR + "}";
        return new SnippetsBlock(ItemResolverConstants.SERVICE, snippet, ItemResolverConstants.SNIPPET_TYPE,
                                SnippetsBlock.SnippetType.SNIPPET, httpImport);
    }

    /**
     * Get Web Socket Service Definition Snippet Block.
     *
     * @return {@link SnippetsBlock}     Generated Snippet Block
     */
    public static SnippetsBlock getWebSocketServiceDefSnippet() {
        ImmutablePair<String, String> httpImport = new ImmutablePair<>("ballerina", "http");
        String snippet = "service ${1:serviceName} on new http:WebSocketListener(9090) {" + CommonUtil.LINE_SEPARATOR +
                "\tresource function onOpen(http:WebSocketCaller caller) {"
                + CommonUtil.LINE_SEPARATOR + "\t\t" + CommonUtil.LINE_SEPARATOR + "\t}" + CommonUtil.LINE_SEPARATOR +
                "\tresource function onText(http:WebSocketCaller caller, string data, boolean finalFrame) {"
                + CommonUtil.LINE_SEPARATOR + "\t\t" + CommonUtil.LINE_SEPARATOR + "\t}" + CommonUtil.LINE_SEPARATOR +
                "\tresource function onClose(http:WebSocketCaller caller, int statusCode, string reason) {"
                + CommonUtil.LINE_SEPARATOR + "\t\t" + CommonUtil.LINE_SEPARATOR + "\t}"
                + CommonUtil.LINE_SEPARATOR + "}";
        return new SnippetsBlock(ItemResolverConstants.SERVICE_WEBSOCKET, snippet, ItemResolverConstants.SNIPPET_TYPE,
                               SnippetsBlock.SnippetType.SNIPPET, httpImport);
    }

    /**
     * Get gRPC Service Definition Snippet Block.
     *
     * @return {@link SnippetsBlock}     Generated Snippet Block
     */
    public static SnippetsBlock getGRPCServiceDefSnippet() {
        ImmutablePair<String, String> grpcImport = new ImmutablePair<>("ballerina", "grpc");
        String snippet = "service ${1:serviceName} on new grpc:Listener(9092) {" + CommonUtil.LINE_SEPARATOR +
                "\tresource function ${2:newResource}(grpc:Caller caller, ${3:string} request) {" +
                CommonUtil.LINE_SEPARATOR + "\t\t" + CommonUtil.LINE_SEPARATOR + "\t}" +
                CommonUtil.LINE_SEPARATOR + "}";
        return new SnippetsBlock(ItemResolverConstants.SERVICE_GRPC, snippet, ItemResolverConstants.SNIPPET_TYPE,
                                SnippetsBlock.SnippetType.SNIPPET, grpcImport);
    }

    /**
     * Get Amazon S3 configuration snippet block
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getAmazonS3ConfigSnippet() {
        ImmutablePair<String, String> configImport = new ImmutablePair<>("ballerina", "config");
        ImmutablePair<String, String> s3Import = new ImmutablePair<>("dilmi", "amazons3");

        String snippet = "amazons3:ClientConfiguration ${1:amazonS3Config} = {" + CommonUtil.LINE_SEPARATOR +
                         "\taccessKeyId: config:getAsString(\"${2:ACCESS_KEY_ID}\")," + CommonUtil.LINE_SEPARATOR +
                         "\tsecretAccessKey: config:getAsString(\"${3:SECRET_ACCESS_KEY}\")" +
                         CommonUtil.LINE_SEPARATOR + "};";

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_CLIENT_CONFIG, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET, configImport,
                                 s3Import);
    }

    /**
     * Get Amazon S3 client snippet block
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getAmazonS3ClientSnippet() {

        String snippet = "amazons3:AmazonS3Client|error ${1:amazonS3Client} = new(${2:amazonS3Config});";

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_CLIENT, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 service snippet block
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getAmazonS3ServiceSnippet() {
        ImmutablePair<String, String> httpImport = new ImmutablePair<>("ballerina", "http");

        String serviceConfig = "@http:ServiceConfig {" + CommonUtil.LINE_SEPARATOR + "\tbasePath: \"/${1:amazons3}\"" +
                               CommonUtil.LINE_SEPARATOR + "}";

        String service = "service ${2:amazonS3Service} on new http:Listener(9090) {" + CommonUtil.LINE_SEPARATOR +
                         CommonUtil.LINE_SEPARATOR + "}";

        String snippet = serviceConfig + CommonUtil.LINE_SEPARATOR + service;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_SERVICE, snippet, ItemResolverConstants.SNIPPET_TYPE,
                                 SnippetsBlock.SnippetType.SNIPPET, httpImport);
    }

    /**
     * Get Amazon S3 create bucket resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3CreateBucketResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"POST\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function createBucket(http:Caller caller, http:Request request, string bucketName) {"
                         + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR + "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_CREATE_BUCKET, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 list bucket resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3listBucketsResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"GET\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function listBuckets(http:Caller caller, http:Request request) {"
                          + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR + "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_LIST_BUCKETS, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 create object resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3CreateObjectResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"POST\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName}/{objectName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function createObject(http:Caller caller, http:Request request, string bucketName, " +
                          "string objectName) {" + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR +
                          "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_CREATE_OBJECT, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 get object resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3GetObjectResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"GET\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName}/{objectName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function getObject(http:Caller caller, http:Request request, string bucketName, " +
                          "string objectName) {" + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR +
                          "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_GET_OBJECT, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 list objects resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3ListObjectsResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"GET\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function listObjects(http:Caller caller, http:Request request, string bucketName) " +
                          "{" + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR + "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_LIST_OBJECTS, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 delete object resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3DeleteObjectResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"DELETE\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName/{objectName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function deleteObject(http:Caller caller, http:Request request, string bucketName, " +
                          "string objectName) { " + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR + "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_DELETE_OBJECT, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get Amazon S3 delete bucket resource snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getS3DeleteBucketResourceSnippet() {
        String resourceConfig = "@http:ResourceConfig {" + CommonUtil.LINE_SEPARATOR +
                                "\tmethods: [\"DELETE\"]," + CommonUtil.LINE_SEPARATOR +
                                "\tpath: \"/{bucketName}\"" + CommonUtil.LINE_SEPARATOR + "}";

        String resource = "resource function deleteBucket(http:Caller caller, http:Request request, string bucketName) { "
                          + CommonUtil.LINE_SEPARATOR + "\t${1}" + CommonUtil.LINE_SEPARATOR + "}";

        String snippet = resourceConfig + CommonUtil.LINE_SEPARATOR + resource;

        return new SnippetsBlock(ItemResolverConstants.AMAZONS3_RESOURCE_DELETE_BUCKET, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET);
    }

    /**
     * Get respond and handle Error snippet
     *
     * @return {@link SnippetsBlock} Generated Snippet Block
     */
    public static SnippetsBlock getRespondAndHandleError() {
        ImmutablePair<String, String> logImport = new ImmutablePair<>("ballerina", "log");

        String createAndSendErrorResponseFunction = "function createAndSendErrorResponse(http:Caller caller, " +
                                                    "string errorMessage, string respondErrorMsg) {" +
                                                    CommonUtil.LINE_SEPARATOR + "\thttp:Response response = new;" +
                                                    CommonUtil.LINE_SEPARATOR + "\tresponse.statusCode = 500;" +
                                                    CommonUtil.LINE_SEPARATOR + "\tresponse.setPayload(<string> " +
                                                    "errorMessage);" + CommonUtil.LINE_SEPARATOR +
                                                    "\trespondAndHandleError(caller, response, respondErrorMsg);" +
                                                    CommonUtil.LINE_SEPARATOR +
                                                    "}";

        String respondAndHandleError = "function respondAndHandleError(http:Caller caller, http:Response response, " +
                                       "string respondErrorMsg) {" + CommonUtil.LINE_SEPARATOR +
                                       "\tvar respond = caller->respond(response);" + CommonUtil.LINE_SEPARATOR +
                                       "\tif (respond is error) {" + CommonUtil.LINE_SEPARATOR +
                                       "\t\tlog:printError(respondErrorMsg, err = respond);" +
                                       CommonUtil.LINE_SEPARATOR +
                                       "\t}" + CommonUtil.LINE_SEPARATOR +
                                       "}";

        String snippet = createAndSendErrorResponseFunction + CommonUtil.LINE_SEPARATOR + CommonUtil.LINE_SEPARATOR +
                         respondAndHandleError;

        return new SnippetsBlock(ItemResolverConstants.RESPOND_AND_HANDLE_ERROR, snippet,
                                 ItemResolverConstants.SNIPPET_TYPE, SnippetsBlock.SnippetType.SNIPPET, logImport);
    }

}
