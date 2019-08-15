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
}
