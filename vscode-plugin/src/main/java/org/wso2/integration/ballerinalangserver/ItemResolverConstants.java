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

public class ItemResolverConstants {

    // Start of Basic Constructs
    public static final String SERVICE = "service/http";
    public static final String SERVICE_WEBSOCKET = "service/webSocket";;
    public static final String SERVICE_GRPC = "service/gRPC";
    public static final String RESOURCE = "resource";
    // End of Basic Constructs

    // Symbol Types Constants
    public static final String SNIPPET_TYPE = "Snippet";
    public static final String RECORD_TYPE = "type <RecordName> record";
    // End Symbol Types Constants

    // AmazonS3 Connector Constructs
    public static final String AMAZONS3_CLIENT_CONFIG = "amazonS3/clientConfiguration";
    public static final String AMAZONS3_CLIENT = "amazonS3/client";
    public static final String AMAZONS3_SERVICE = "amazons3/service";
    public static final String AMAZONS3_RESOURCE_CREATE_BUCKET = "amazonS3/resource/createBucket";
    public static final String AMAZONS3_RESOURCE_LIST_BUCKETS = "amazonS3/resource/listBuckets";
    public static final String AMAZONS3_RESOURCE_CREATE_OBJECT = "amazonS3/resource/createObject";
    public static final String AMAZONS3_RESOURCE_GET_OBJECT = "amazonS3/resource/getObject";
    public static final String AMAZONS3_RESOURCE_LIST_OBJECTS = "amazonS3/resource/listObjects";
    public static final String AMAZONS3_RESOURCE_DELETE_OBJECT = "amazonS3/resource/deleteObject";
    public static final String AMAZONS3_RESOURCE_DELETE_BUCKET = "amazonS3/resource/deleteBucket";

    //Error Handling constructs
    public static final String RESPOND_AND_HANDLE_ERROR = "handleError";

}
