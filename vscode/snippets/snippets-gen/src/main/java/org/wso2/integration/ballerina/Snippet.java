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

package org.wso2.integration.ballerina;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Generates the Snippet object from the input .txt files.
 */
public class Snippet {

    private static final Logger log = LoggerFactory.getLogger(Snippet.class);

    private String name;
    private String imports;
    private String trigger;
    private String code;

    public Snippet(String name, String imports, String trigger, String code) {

        this.name = name;
        this.imports = imports;
        this.trigger = trigger;
        this.code = code;
    }

    public Snippet() {}

    public Snippet(String trigger) {
        this.trigger = trigger;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;

        if (name == null) {
            log.debug("Name of the snippet is not provided");
            throw new IllegalArgumentException();
        }
    }

    public String getImports() {
        return imports;
    }

    public void setImports(String imports) {
        this.imports = imports;

        if (imports == null) {
            log.debug("Imports of the snippet is not provided");
            throw new IllegalArgumentException();
        }
    }

    public String getTrigger() {
        return trigger;
    }

    public void setTrigger(String trigger) {
        this.trigger = trigger;

        if (trigger == null) {
            log.debug("Trigger of the snippet is not provided");
            throw new IllegalArgumentException();
        }
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;

        if (code == null) {
            log.debug("Snippet Content for the snippet is not provided");
            throw new IllegalArgumentException();
        }
    }
}
