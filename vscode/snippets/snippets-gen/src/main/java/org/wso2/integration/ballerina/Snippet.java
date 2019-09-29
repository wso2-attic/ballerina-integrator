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

public class Snippet {
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

    public Snippet() {
    }

    public Snippet(String trigger) {
        this.trigger = trigger;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getImports() {
        return imports;
    }

    public void setImports(String imports) {

        this.imports = imports;
    }

    public String getTrigger() {
        return trigger;
    }

    public void setTrigger(String trigger) {
        this.trigger = trigger;

        this.trigger = "public static final String " + name + "=" + this.trigger;

    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;

        String resourceConfig = "";
        String resource = "";
    }
}
