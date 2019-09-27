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
import ballerina/mime;

// The stock quote management is done using the SimpleStockQuoteService.
// Define a listener endpoint:
listener http:Listener httpListener = new(9090);

// Constants.
const string STOCK_QUOTE_SERVICE_BASE_URL = "http://localhost:9000";
const string ERROR_MESSAGE_WHEN_RESPOND = "Error while sending response to the client";
const string ERROR_MESSAGE_INVALID_PAYLOAD = "Invalid payload received";

http:Client stockQuoteClient = new(STOCK_QUOTE_SERVICE_BASE_URL);

// RESTful service.
@http:ServiceConfig { basePath: "/stockQuote" }
service stockQuote on httpListener {

    // Resource that handles the HTTP GET requests that are directed to a specific stock using path '/quote/<symbol>'.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/quote/{symbol}"
    }
    resource function getQuote(http:Caller caller, http:Request request, string symbol) {
        // Find the quote details of a single stock. The response contains the last sale price of the stock.
        xml payload = xml `<m0:getQuote xmlns:m0="http://services.samples">
                               <m0:request>
                                   <m0:symbol>${symbol}</m0:symbol>
                               </m0:request>
                           </m0:getQuote>`;
        xml soapEnv = self.constructSOAPPayload(untaint payload, "http://schemas.xmlsoap.org/soap/envelope/");

        request.addHeader("SOAPAction", "urn:getQuote");
        request.setXmlPayload(soapEnv);
        request.setHeader(mime:CONTENT_TYPE, mime:TEXT_XML);

        var httpResponse = stockQuoteClient->post("/services/SimpleStockQuoteService", untaint request);

        if (httpResponse is http:Response) {
            self.respondToClient(caller, httpResponse, ERROR_MESSAGE_WHEN_RESPOND);
        } else {
            self.createAndSendErrorResponse(caller, untaint <string>httpResponse.detail().message,
            ERROR_MESSAGE_WHEN_RESPOND, 500);
        }
    }

    // Resource that handles the HTTP POST requests that are directed to the path '/order' to create a new Order.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        var orderReq = request.getXmlPayload();
        if (orderReq is xml) {
            string price = orderReq.Price.getTextValue();
            string quantity = orderReq.Quantity.getTextValue();
            string symbol = orderReq.Symbol.getTextValue();
            xml payload = xml `<m:placeOrder xmlns:m="http://services.samples">
                                   <m:order>
                                       <m:price>${price}</m:price>
                                       <m:quantity>${quantity}</m:quantity>
                                       <m:symbol>${symbol}</m:symbol>
                                   </m:order>
                               </m:placeOrder>`;
            xml soapEnv = self.constructSOAPPayload(untaint payload, "http://schemas.xmlsoap.org/soap/envelope/");

            request.addHeader("SOAPAction", "urn:placeOrder");
            request.setXmlPayload(soapEnv);
            request.setHeader(mime:CONTENT_TYPE, mime:TEXT_XML);

            var httpResponse = stockQuoteClient->post("/services/SimpleStockQuoteService", untaint request);
            if (httpResponse is http:Response) {
                if (httpResponse.statusCode == 202) {
                    httpResponse.statusCode = 201;
                    httpResponse.reasonPhrase = "Created";
                    httpResponse.setHeader("Location", "http://localhost:9090/stockQuote/quote/" + symbol);

                    // Create response message.
                    xml responsePayload = xml `<ns:placeOrderResponse xmlns:ns="http://services.samples">
                                                   <ns:response xmlns:ax21="http://services.samples/xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ax21:placeOrderResponse">
                                                       <ax21:status>Order has been created</ax21:status>
                                                   </ns:response>
                                               </ns:placeOrderResponse>`;
                    httpResponse.setXmlPayload(untaint responsePayload);
                }
                // Send response to the client.
                self.respondToClient(caller, httpResponse, ERROR_MESSAGE_WHEN_RESPOND);
            } else {
                self.createAndSendErrorResponse(caller, untaint <string>httpResponse.detail().message,
                ERROR_MESSAGE_WHEN_RESPOND, 500);
            }
        } else {
            self.createAndSendErrorResponse(caller, ERROR_MESSAGE_INVALID_PAYLOAD, ERROR_MESSAGE_WHEN_RESPOND, 400);
        }
    }

    // Function to create the error response.
    function createAndSendErrorResponse(http:Caller caller, string backendError, string errorMsg, int statusCode) {
        http:Response response = new;
        // Set status code to the error response.
        response.statusCode = statusCode;
        // Set the error message to the response payload.
        response.setPayload(<string> backendError);
        self.respondToClient(caller, response, errorMsg);
    }

    // Function to send the response back to the client.
    function respondToClient(http:Caller caller, http:Response response, string errorMsg) {
        // Send response to the caller.
        var respond = caller->respond(response);
        if (respond is error) {
            log:printError(errorMsg, err = respond);
        }
    }

    function constructSOAPPayload (xml payload, string namespace) returns xml {
        xml soapPayload = xml `<soapenv:Envelope xmlns:soapenv="${namespace}">
                                   <soapenv:Header/>
                                   <soapenv:Body>${payload}</soapenv:Body>
                               </soapenv:Envelope>`;
        return soapPayload;
    }
}
