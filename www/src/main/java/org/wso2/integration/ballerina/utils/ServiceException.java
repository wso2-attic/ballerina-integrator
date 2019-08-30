/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
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

package org.wso2.integration.ballerina.utils;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Custom exception class used in site builder.
 */
public class ServiceException extends RuntimeException {

    private static final Pattern REPLACE_PATTERN = Pattern.compile("\\{\\}");

    private static String generateMessage(String message, Object... args) {
        int index = 0;
        Matcher matcher = REPLACE_PATTERN.matcher(message);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            matcher.appendReplacement(sb, Matcher.quoteReplacement(String.valueOf(args[index++])));
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    public ServiceException(String message, Object... args) {
        super((args.length > 0) ? generateMessage(message, args) : message);
    }

    public ServiceException(String message, Throwable cause, Object... args) {
        super((args.length > 0) ? generateMessage(message, args) : message, cause);
    }
}



