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
import ballerina/jsonutils;
import wso2/soap;

soap:Soap11Client soapEP = new("http://localhost:9000/services/SimpleStockQuoteService");

@http:ServiceConfig {
    basePath: "/stockQuote"
}
service stockQuote on new http:Listener(9090) {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/quote/{symbol}"
    }
    resource function getQuote(http:Caller caller, http:Request request, string symbol) {
        xmlns "http://services.samples" as m0; 
        xml payload = xml `<m0:symbol>${symbol}</m0:symbol>`; 
        soap:SoapResponse soapResponse = checkpanic soapEP->sendReceive(payload, "urn:getQuote"); 
        xml responsePayload = checkpanic soapResponse.httpResponse.getXmlPayload(); 
        http:Response response = new;
        response.setJsonPayload(<@untainted>checkpanic jsonutils:fromXML(responsePayload.Body.getQuoteResponse,
            {preserveNamespaces: false}));        
        error? respond = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        json orderReq = checkpanic request.getJsonPayload();
        string price = orderReq.price != null ? orderReq.price.toString() : "";
        string quantity = orderReq.quantity != null ? orderReq.quantity.toString() : "";
        string symbol = orderReq.symbol != null ? orderReq.symbol.toString() : "";
        xmlns "http://services.samples" as m;
        xml payload = xml `<m:placeOrder>
                                <m:order>
                                    <m:price>${price}</m:price>
                                    <m:quantity>${quantity}</m:quantity>
                                    <m:symbol>${symbol}</m:symbol>
                                </m:order>
                            </m:placeOrder>`;
        soap:SoapResponse soapResponse = checkpanic soapEP->sendReceive(<@untainted> payload, "urn:placeOrder"); 
        xml responsePayload = checkpanic soapResponse.httpResponse.getXmlPayload(); 
        http:Response response = new;
        response.setJsonPayload(<@untainted>checkpanic jsonutils:fromXML(responsePayload.Body.placeOrderResponse,
            {preserveNamespaces: false}));
        error? respond = caller->respond(<@untainted> response);
    }
}
