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

package org.wso2.integration.util;

import org.wso2.integration.ballerinalangserver.SnippetsBlock;
import org.wso2.integration.ballerinalangserver.SnippetsGenerator;

    /**
     * Snippets for the Ballerina Integrator.
     */

public enum Snippets {

    DEF_RECORD(SnippetsGenerator.getRecordDefinitionSnippet()),
    DEF_RESOURCE_HTTP(SnippetsGenerator.getHttpResourceDefinitionSnippet()),
    DEF_SERVICE_WEBSOCKET(SnippetsGenerator.getWebSocketServiceDefSnippet()),
    DEF_SERVICE_GRPC(SnippetsGenerator.getGRPCServiceDefSnippet()),
    DEF_SERVICE_AMAZONS3(SnippetsGenerator.getAmazonS3ServiceSnippet()),
    DEF_RESOURCE_S3_CREATE_BUCKET(SnippetsGenerator.getS3CreateBucketResourceSnippet()),
    DEF_RESOURCE_S3_LIST_BUCKETS(SnippetsGenerator.getS3listBucketsResourceSnippet()),
    DEF_RESOURCE_S3_CREATE_OBJECT(SnippetsGenerator.getS3CreateObjectResourceSnippet()),
    DEF_RESOURCE_S3_GET_OBJECT(SnippetsGenerator.getS3GetObjectResourceSnippet()),
    DEF_RESOURCE_S3_LIST_OBJECTS(SnippetsGenerator.getS3ListObjectsResourceSnippet()),
    DEF_RESOURCE_S3_DELETE_OBJECT(SnippetsGenerator.getS3DeleteObjectResourceSnippet()),
    DEF_RESOURCE_S3_DELETE_BUCKET(SnippetsGenerator.getS3DeleteBucketResourceSnippet()),
    DEF_CLIENT_CONFIG_AMAZONS3(SnippetsGenerator.getAmazonS3ConfigSnippet()),
    DEF_CLIENT_AMAZONS3(SnippetsGenerator.getAmazonS3ClientSnippet()),
    DEF_ERROR_HANDLING(SnippetsGenerator.getRespondAndHandleError());

    private String snippetName;
    private SnippetsBlock snippetBlock;

    Snippets(SnippetsBlock snippetBlock) {
        this.snippetName = null;
        this.snippetBlock = snippetBlock;
    }

    Snippets(String snippetName, SnippetsBlock snippetBlock) {
        this.snippetName = snippetName;
        this.snippetBlock = snippetBlock;
    }

    /**
     * Get the Snippet Name.
     *
     * @return {@link String} snippet name
     */
    public String snippetName() {
        return this.snippetName;
    }

    /**
     * Get the SnippetBlock.
     *
     * @return {@link SnippetsBlock} SnippetBlock
     */
    public SnippetsBlock get() {
        return this.snippetBlock;
    }
}
