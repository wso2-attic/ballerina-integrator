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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/stringutils;

const string GET_QUOTE = "urn:getQuote";
const string PLACE_ORDER = "urn:placeOrder";

@http:ServiceConfig {
    basePath: "/services"
}
service services on new http:Listener(9000) {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/SimpleStockQuoteService"
    }
    resource function SimpleStockQuoteService(http:Caller caller, http:Request request) {
        log:printInfo("Stock quote service invoked.");
        
        string contentType = request.getHeader("Content-Type");
        boolean isSOAP11 = stringutils:contains(contentType,"text/xml");

        string soapAction = "";
        if (isSOAP11){
            soapAction = validateSoap11Action(request.getHeader("SOAPAction"));
        } else {
            soapAction = validateSoap12Action(contentType);
        }
        xml requestPayload = checkpanic request.getXmlPayload();
        string company = requestPayload.Body.getQuote.request.symbol.getTextValue();
        http:Response response = new; 
        match soapAction {
            GET_QUOTE => {
                response.setXmlPayload(<@untainted> getQuote(company,isSOAP11));
                log:printInfo("Stock quote generated.");                
            }
            PLACE_ORDER => {
                response.setXmlPayload(<@untainted> placeOrder(isSOAP11));
                log:printInfo("The order was placed.");
            }
            _ => {
                response.statusCode = http:STATUS_BAD_REQUEST;
                response.setTextPayload("Unsupported Action!!!");
            }
        }
        if (isSOAP11){ 
            response.setContentType("text/xml");
        } else {
            response.setContentType("application/soap+xml");
        }
        error? respond = caller->respond(response);
    }
}

function getQuote(string company, boolean isSOAP11) returns xml {
    xmlns "http://services.samples" as ns;
    xmlns "http://services.samples/xsd" as ax21;
    xml body = xml `<ns:getQuoteResponse>
                        <ax21:change>-2.86843917118114</ax21:change>
                        <ax21:earnings>-8.540305401672558</ax21:earnings>
                        <ax21:high>-176.67958828498735</ax21:high>
                        <ax21:last>177.66987465262923</ax21:last>
                        <ax21:low>-176.30898912339075</ax21:low>
                        <ax21:marketCap>5.649557998178506E7</ax21:marketCap>
                        <ax21:name>${company} Company</ax21:name>
                        <ax21:open>185.62740369461244</ax21:open>
                        <ax21:peRatio>24.341353665128693</ax21:peRatio>
                        <ax21:percentageChange>-1.4930577008849097</ax21:percentageChange>
                        <ax21:prevClose>192.11844053187397</ax21:prevClose>
                        <ax21:symbol>${company}</ax21:symbol>
                        <ax21:volume>7791</ax21:volume>
                    </ns:getQuoteResponse>`;
    if (isSOAP11) {
        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
         xml responsePayload = xml `<soapenv:Envelope>
                                        <soapenv:Body>${body}</soapenv:Body>
                                    </soapenv:Envelope>`;
        return responsePayload;
    } else {
        xmlns "http://www.w3.org/2003/05/soap-envelope" as soapenv;
         xml responsePayload = xml `<soapenv:Envelope>
                                        <soapenv:Body>${body}</soapenv:Body>
                                    </soapenv:Envelope>`;
        return responsePayload;
    }
}

function placeOrder(boolean isSOAP11) returns xml {
    xmlns "http://services.samples" as ns;
    xmlns "http://services.samples/xsd" as ax21;
    xml body = xml `<ns:placeOrderResponse>
                        <ax21:status>created</ax21:status>
                    </ns:placeOrderResponse>`;
    if (isSOAP11) {
        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
         xml responsePayload = xml `<soapenv:Envelope>
                                        <soapenv:Body>${body}</soapenv:Body>
                                    </soapenv:Envelope>`;
        return responsePayload;
    } else {
        xmlns "http://www.w3.org/2003/05/soap-envelope" as soapenv;
         xml responsePayload = xml `<soapenv:Envelope>
                                        <soapenv:Body>${body}</soapenv:Body>
                                    </soapenv:Envelope>`;
        return responsePayload;
    }
}

function validateSoap11Action(string soapAction) returns string {
    if (soapAction.startsWith("\"urn:")){
        // Remove `"` from soap action.
        return stringutils:replace(soapAction, "\"", "");
    } else if (soapAction.startsWith("\\\"urn:")){
        // Remove `\"` from soap action.
        return stringutils:replace(soapAction, "\\\"", "");
    }
    return soapAction;
}

function validateSoap12Action(string contentType) returns string {
    if (stringutils:contains(contentType, GET_QUOTE)){
        return GET_QUOTE;
    } else if (stringutils:contains(contentType, PLACE_ORDER)){
        return PLACE_ORDER;
    }
    return "";
}
