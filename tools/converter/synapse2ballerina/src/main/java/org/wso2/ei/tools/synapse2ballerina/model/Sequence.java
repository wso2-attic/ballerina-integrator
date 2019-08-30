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

package org.wso2.ei.tools.synapse2ballerina.model;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlElements;

/**
 * Represents synapse sequence
 */
public class Sequence {
    private String name;
    private String type;
    private List<Mediator> mediatorList = new ArrayList<>();

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public List<Mediator> getMediatorList() {
        return mediatorList;
    }

    @XmlElements({
                         @XmlElement(name = "call",
                                     type = CallMediator.class),
                         @XmlElement(name = "respond",
                                     type = RespondMediator.class),
                         @XmlElement(name = "payloadFactory",
                                     type = PayloadFactoryMediator.class)
                 })
    public void setMediator(Mediator mediator) {
        this.mediatorList.add(mediator);
    }

}
