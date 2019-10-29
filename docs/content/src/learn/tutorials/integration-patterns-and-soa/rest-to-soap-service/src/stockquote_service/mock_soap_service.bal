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
        string soapAction = validateSoapAction(request.getHeader("SOAPAction"));
        xml requestPayload = checkpanic request.getXmlPayload();
        string company = requestPayload.Body.symbol.getTextValue();
        http:Response response = new; 
        match soapAction {
            "urn:getQuote" => {
                response.setXmlPayload(<@untainted> getQuote(company));
                log:printInfo("Stock quote generated.");                
            }
            "urn:placeOrder" => {
                response.setXmlPayload(<@untainted> placeOrder());
                log:printInfo("The order was placed.");
            }
            _ => {
                response.statusCode = http:STATUS_BAD_REQUEST;
                response.setTextPayload("Unsupported Action!!!");
            }
        }
        error? respond = caller->respond(response);
    }
}

function getQuote(string company) returns xml {
    xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
    xmlns "http://services.samples" as ns;
    xmlns "http://services.samples/xsd" as ax21;
    xml responsePayload = xml `<soapenv:Envelope>
                                    <soapenv:Body>
                                        <ns:getQuoteResponse>
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
                                        </ns:getQuoteResponse>
                                    </soapenv:Body>
                                </soapenv:Envelope>`;

    return responsePayload;
}

function placeOrder() returns xml {
    xmlns "http://schemas.xmlsoap.org/soap/envelope/" as soapenv;
    xmlns "http://services.samples" as ns;
    xmlns "http://services.samples/xsd" as ax21;
    xml responsePayload = xml `<soapenv:Envelope>
                                    <soapenv:Body>
                                        <ns:placeOrderResponse>
                                                <ax21:status>created</ax21:status>
                                        </ns:placeOrderResponse>
                                    </soapenv:Body>
                                </soapenv:Envelope>`;
    return responsePayload;
}

function validateSoapAction(string soapAction) returns string {
    if (soapAction.startsWith("urn:")) {
        return soapAction;
    } else {
        // Remove `\"` from soap action.
        return stringutils:replace(soapAction, "\\\"", "");
    }
}
