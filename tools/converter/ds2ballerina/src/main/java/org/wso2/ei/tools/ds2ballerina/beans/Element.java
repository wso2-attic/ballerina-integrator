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

package org.wso2.ei.tools.ds2ballerina.beans;

import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * Object for element element in result element.
 */
@XmlRootElement(name = "element") public class Element {

    @XmlAttribute private String name;
    @XmlAttribute private String export;
    @XmlAttribute private String exportType;
    @XmlAttribute private String namespace;
    @XmlAttribute private String arrayName;
    @XmlAttribute private boolean optional;
    @XmlAttribute private String column;
    @XmlAttribute(name = "query-param") private String queryParam;
    @XmlAttribute private String xsdType;

    public String getXsdType() {
        return xsdType;
    }

    public String getName() {
        return name;
    }

    public String getExport() {
        return export;
    }

    public String getExportType() {
        return exportType;
    }

    public String getNamespace() {
        return namespace;
    }

    public String getArrayName() {
        return arrayName;
    }

    public boolean isOptional() {
        return optional;
    }
}
