/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.ei.tools.mule2ballerina.util;

import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Maintains the log levels needed for Ballerina object stack population
 */
public enum LogLevel {

    LOG_TRACE("TRACE", "1"),
    LOG_DEBUG("DEBUG", "2"),
    LOG_INFO("INFO", "3"),
    LOG_WARN("WARN", "4"),
    LOG_ERROR("ERROR", "5");

    LogLevel(String level, String value) {
        this.value = value;
        this.level = level;
    }

    private String value;
    private String level;
    private static final Map<String, LogLevel> ENUM_MAP;

    public String getValue() {
        return value;
    }

    public String getLevel() {
        return level;
    }

    // Build an immutable map of String name to enum pairs.
    static {
        Map<String, LogLevel> map = new ConcurrentHashMap<String, LogLevel>();
        for (LogLevel instance : LogLevel.values()) {
            map.put(instance.getLevel(), instance);
        }
        ENUM_MAP = Collections.unmodifiableMap(map);
    }

    public static LogLevel get(String level) {
        return ENUM_MAP.get(level);
    }
}
