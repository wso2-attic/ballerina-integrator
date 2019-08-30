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

package org.wso2.ei.tools.mule2ballerina.model;

import org.wso2.ei.tools.mule2ballerina.dto.DataCarrierDTO;

import java.util.LinkedList;
import java.util.Queue;

/**
 * {@code SubFlow} represents sub-flow element
 */
public class SubFlow extends BaseObject {
    protected String name;
    protected Queue<Processor> flowProcessors; //Processors belong to a sub flow in FIFO order

    public SubFlow() {
        flowProcessors = new LinkedList<Processor>();
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Queue<Processor> getFlowProcessors() {
        return flowProcessors;
    }

    public void addProcessor(Processor processor) {
        flowProcessors.add(processor);
    }

    /**
     * Adds the sub flow to the root
     *
     * @param dataCarrierDTO
     */
    @Override
    public void buildTree(DataCarrierDTO dataCarrierDTO) {

        BaseObject muleObj = dataCarrierDTO.getBaseObject();
        Root rootObj = dataCarrierDTO.getRootObject();

        SubFlow subFlow = (SubFlow) muleObj;
        if (dataCarrierDTO.isSubFlowStarted()) {
            rootObj.addSubFlow(subFlow.getName(), subFlow);
        }
    }

}
