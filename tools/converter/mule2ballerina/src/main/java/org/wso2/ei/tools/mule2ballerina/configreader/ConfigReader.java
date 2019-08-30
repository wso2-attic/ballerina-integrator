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

package org.wso2.ei.tools.mule2ballerina.configreader;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.ei.tools.mule2ballerina.dto.DataCarrierDTO;
import org.wso2.ei.tools.mule2ballerina.elementmapper.AttributeMapper;
import org.wso2.ei.tools.mule2ballerina.elementmapper.ElementMapper;
import org.wso2.ei.tools.mule2ballerina.model.BaseObject;
import org.wso2.ei.tools.mule2ballerina.model.Comment;
import org.wso2.ei.tools.mule2ballerina.model.Root;
import org.wso2.ei.tools.mule2ballerina.util.Constant;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import javax.xml.namespace.QName;
import javax.xml.stream.XMLEventReader;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.Attribute;
import javax.xml.stream.events.EndElement;
import javax.xml.stream.events.StartElement;
import javax.xml.stream.events.XMLEvent;

/**
 * {@code ConfigReader} class reads mule configuration file and builds the intermediate object stack
 */
public class ConfigReader {

    private static Logger logger = LoggerFactory.getLogger(ConfigReader.class);

    private ElementMapper mapperObject;
    private AttributeMapper attributeMapper;
    private Root rootObj;
    private boolean flowStarted = false;
    private boolean subFlowStarted = false;
    private boolean asyncFlowStarted = false;
    private List<String> unIdentifiedElements;

    public ConfigReader() {
        mapperObject = new ElementMapper();
        attributeMapper = new AttributeMapper();
        rootObj = new Root();
        unIdentifiedElements = new ArrayList<String>();
    }

    /**
     * Process XML as a stream of events
     *
     * @param inputStream
     */
    public void readXML(InputStream inputStream) {
        XMLInputFactory xmlInputFactory = XMLInputFactory.newInstance();
        try {
            XMLEventReader eventReader = xmlInputFactory.createXMLEventReader(inputStream);

            while (eventReader.hasNext()) {
                XMLEvent xmlEvent = eventReader.nextEvent();
                switch (xmlEvent.getEventType()) {
                case XMLStreamConstants.START_ELEMENT:
                    StartElement startElement = xmlEvent.asStartElement();
                    checkFlowState(getElementOrAttributeName(startElement.getName()), true);
                    loadIntermediateMuleObjects(startElement);
                    break;

                case XMLStreamConstants.CHARACTERS:
                    break;

                case XMLStreamConstants.END_ELEMENT:
                    EndElement endElement = xmlEvent.asEndElement();
                    checkFlowState(getElementOrAttributeName(endElement.getName()), false);
                    break;

                default:
                    break;
                }
            }
        } catch (XMLStreamException e) {
            logger.error(e.getMessage(), e);
        }
    }

    /**
     * Given a mule configuration file get it's inputstream
     *
     * @param file Mule configuration file
     * @return input stream
     */
    public InputStream getInputStream(File file) {
        FileInputStream fileInputStream = null;
        try {
            fileInputStream = new FileInputStream(file);
        } catch (FileNotFoundException e) {
            logger.error(e.getMessage(), e);
        }
        return fileInputStream;
    }

    /**
     * Populate relevant intermediate object that is mapped to mule element
     * If the mule element is not mapped to an object, put it in an unidentified element list and make a comment in
     * ballerina code specifying that feature should be manually handled.
     *
     * @param mElement represents any mule element
     */
    private void loadIntermediateMuleObjects(StartElement mElement) {
        String mElementName = getElementName(mElement);
        String mClassName = mapperObject.getElementToObjMapper().get(mElementName);
        Class<?> intermediateClass = null;
        if (mClassName != null) {
            try {
                intermediateClass = Class.forName(mClassName);
                populateIntermediateObject(mElement.getAttributes(), intermediateClass);

            } catch (ClassNotFoundException e) {
                logger.error(e.getMessage(), e);
            }
        } else {
            if (!Constant.MULE_TAG.equals(mElementName)) {
                unIdentifiedElements.add(mElementName);
                Comment comment = new Comment();
                comment.setComment(" //IMPORTANT: Functionality provided by " + mElementName + " should be handled "
                        + "manually here");
                DataCarrierDTO dataCarrierDTO = populateDataCarrier(comment);
                comment.buildTree(dataCarrierDTO);
            }
        }
    }

    /**
     * Get mule element's name with the prefix in string format
     *
     * @param muleElement represents a mule tag
     * @return
     */
    private String getElementName(StartElement muleElement) {
        QName qName = (muleElement != null ? muleElement.getName() : null);
        return getElementOrAttributeName(qName);
    }

    /**
     * Get  mule attribute name with the prefix in string format
     *
     * @param attribute mule attribute
     * @return
     */
    private String getAttributeName(Attribute attribute) {
        QName qName = (attribute != null ? attribute.getName() : null);
        return getElementOrAttributeName(qName);
    }

    /**
     * Given a valid identifier for a mule element or an attribute, get string value of it with the prefix attached
     * to it
     *
     * @param qName valid identifier for mule element or attribute
     * @return
     */
    private String getElementOrAttributeName(QName qName) {
        String prefix = (qName != null ? qName.getPrefix() : "");
        String mainElement = (qName != null ? qName.getLocalPart() : "");
        String name = (prefix != null && !prefix.equals("") ? (prefix + ":" + mainElement) : mainElement);
        return name;
    }

    /**
     * Populate intermediate object properties with mule attribute values and add that element in its proper place in
     * the intermediate object stack
     *
     * @param attributes List of attributes associate with a mule element
     * @param mClass     Intermediate class that is mapped to the mule element
     */
    private void populateIntermediateObject(Iterator<Attribute> attributes, Class<?> mClass) {
        try {
            java.lang.Object object = mClass.newInstance();

            attributes.forEachRemaining(attribute -> {
                try {
                    String property = attributeMapper.getmAttributeMapper().get(getAttributeName(attribute));
                    if (property != null) {
                        Field field = mClass.getDeclaredField(property);
                        field.setAccessible(true);
                        field.set(object, attribute.getValue());
                    }
                } catch (NoSuchFieldException e) {
                    logger.warn(
                            " NoSuchFieldException : There can be attributes in mule xml that is not " + "mapped " + e);
                } catch (IllegalAccessException e) {
                    logger.error(e.getMessage(), e);
                }
            });

            BaseObject muleObj = (BaseObject) object;
            DataCarrierDTO dataCarrierDTO = populateDataCarrier(muleObj);
            muleObj.buildTree(dataCarrierDTO);

        } catch (IllegalAccessException e) {
            logger.error(e.getMessage(), e);
        } catch (InstantiationException e) {
            logger.error(e.getMessage(), e);
        }
    }

    /**
     * Given a mule element, if it's a flow or a subflow, determine the flow start or end.
     *
     * @param startOrEndElement start or end tag of any mule element
     * @param isFlowStarted     Track flow start or end
     */
    private void checkFlowState(String startOrEndElement, boolean isFlowStarted) {
        switch (startOrEndElement) {
        case Constant.MULE_FLOW:
            flowStarted = isFlowStarted;
            break;
        case Constant.MULE_SUB_FLOW:
            subFlowStarted = isFlowStarted;
            break;
        case Constant.MULE_ASYNC_FLOW:
            asyncFlowStarted = isFlowStarted;
            break;
        default:
            break;
        }
    }

    /**
     * Populate DataCarrierDTO with necessary details, so that the intermediate object can be inserted in it's proper
     * place in the intermediate stack
     *
     * @param baseObject represents any intermediate object
     * @return
     */
    private DataCarrierDTO populateDataCarrier(BaseObject baseObject) {
        DataCarrierDTO dataCarrierDTO = new DataCarrierDTO();
        dataCarrierDTO.setBaseObject(baseObject);
        dataCarrierDTO.setRootObject(rootObj);
        dataCarrierDTO.setFlowStarted(flowStarted);
        dataCarrierDTO.setSubFlowStarted(subFlowStarted);
        dataCarrierDTO.setAsyncFlowStarted(asyncFlowStarted);
        return dataCarrierDTO;
    }

    /**
     * Get the root of the intermediate stack that holds all the intermediate objects
     *
     * @return
     */
    public Root getRootObj() {
        return rootObj;
    }

    public void setRootObj(Root rootObj) {
        this.rootObj = rootObj;
    }

    /**
     * Get unidentified elements as a list of strings
     *
     * @return
     */
    public List<String> getUnIdentifiedElements() {
        return unIdentifiedElements;
    }

}
