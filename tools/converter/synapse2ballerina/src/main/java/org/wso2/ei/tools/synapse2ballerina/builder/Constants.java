/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.ei.tools.synapse2ballerina.builder;

/**
 * Constants for build the ballerina source file
 */
public class Constants {

    public static final String BLANG_HTTP = "http";
    public static final String BLANG_BASEPATH = "BasePath";
    public static final String BLANG_VALUE = "value";
    public static final String BLANG_METHOD_GET = "GET";
    public static final String BLANG_TYPE_MESSAGE = "message";
    public static final String BLANG_TYPE_JSON = "json";
    public static final String BLANG_PATH = "Path";

    public static final String BLANG_RESOURCE_NAME = "myResource";
    public static final String BLANG_SERVICE_NAME = "myService";

    public static final String BLANG_PKG_MESSAGES = "messages";
    public static final String BLANG_PKG_MESSAGES_FUNC = "setStringPayload";
    public static final String BLANG_PKG_MESSAGES_SET_XML_PAYLOAD = "setXmlPayload";

    public static final String BLANG_CLIENT_CONNECTOR = "ClientConnector";
    public static final String BLANG_CLIENT_CONNECTOR_GET_ACTION = "get";

    public static final String BLANG_DEFAULT_MSG_PARAM_NAME = "msg";
    public static final String BLANG_RES_VARIABLE_NAME = "response";
    public static final String BLANG_CONNECT_VARIABLE_NAME = "connectRef";

    public static final String RESPONSE_VAR_NAME = "RESPONSE_VAR_NAME";
    public static final String RESOURCE_PARAM_NAME = "RESOURCE_PARAM_NAME";
}
