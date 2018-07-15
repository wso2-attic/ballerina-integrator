// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import wso2/kafka;

// Constants to store admin credentials
@final string ADMIN_USERNAME = "Admin";
@final string ADMIN_PASSWORD = "Admin";

// Kafka producer endpoint
endpoint kafka:SimpleProducer kafkaProducer {
    bootstrapServers: "localhost:9092",
    clientID:"basic-producer",
    acks:"all",
    noRetries:3
};

// HTTP service endpoint
endpoint http:Listener listener {
    port:9090
};

@http:ServiceConfig {basePath:"/product"}
service<http:Service> productAdminService bind listener {

    @http:ResourceConfig {methods:["POST"], consumes:["application/json"],
        produces:["application/json"]}
    updatePrice (endpoint client, http:Request request) {
        http:Response response;
        json reqPayload;
        float newPriceAmount;

        // Try parsing the JSON payload from the request
        match request.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(response);
                done;
            }
        }

        json username = reqPayload.Username;
        json password = reqPayload.Password;
        json productName = reqPayload.Product;
        json newPrice = reqPayload.Price;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (username == null || password == null || productName == null || newPrice == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request: Invalid payload"});
            _ = client->respond(response);
            done;
        }

        // Convert the price value to float
        var result = <float>newPrice.toString();
        match result {
            float value => {
                newPriceAmount = value;
            }
            error err => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid amount specified"});
                _ = client->respond(response);
                done;
            }
        }

        // If the credentials does not match with the admin credentials,
        // send an "Access Forbidden" response message
        if (username.toString() != ADMIN_USERNAME || password.toString() != ADMIN_PASSWORD) {
            response.statusCode = 403;
            response.setJsonPayload({"Message":"Access Forbidden"});
            _ = client->respond(response);
            done;
        }

        // Construct and serialize the message to be published to the Kafka topic
        json priceUpdateInfo = {"Product":productName, "UpdatedPrice":newPriceAmount};
        byte[] serializedMsg = priceUpdateInfo.toString().toByteArray("UTF-8");

        // Produce the message and publish it to the Kafka topic
        kafkaProducer->send(serializedMsg, "product-price", partition = 0);
        // Send a success status to the admin request
        response.setJsonPayload({"Status":"Success"});
        _ = client->respond(response);
    }
}
