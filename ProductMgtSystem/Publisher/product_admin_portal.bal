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
import ballerina/log;

// Constants to store admin credentials
@final
string ADMIN_USERNAME = "Admin";
@final
string ADMIN_PASSWORD = "Admin";

// Kafka ProducerClient endpoint
endpoint kafka:ProducerEndpoint kafkaProducer {
    bootstrapServers: "localhost:9092",
    clientID:"basic-producer",
    acks:"all",
    noRetries:3
};

// HTTP service endpoint
endpoint http:Listener serviceEP {
    port:9090
};

@http:ServiceConfig {
    endpoints:[serviceEP],
    basePath:"/product"
}
service<http:Service> productAdminService bind serviceEP {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/updatePrice",
        consumes:["application/json"],
        produces:["application/json"]
    }
    updatePrice (endpoint connection, http:Request request) {
        http:Response response = new;

        // Try getting the JSON payload from the incoming request
        json payload = check request.getJsonPayload();
        json username = payload.Username;
        json password = payload.Password;
        json productName = payload.Product;
        json newPrice = payload.Price;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (username == null || password == null || productName == null || newPrice == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request: Invalid payload"});
            _ = connection->respond(response);
        }

        float newPriceAmount;

        // Convert the price value to float
        var result = <float>newPrice.toString();
        match result {
            float value => {
                newPriceAmount = value;
            }

            error err => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid amount specified for field 'Price'"});
                connection->respond(response) but { error e => log:printError("Error in responding ", err = e) };
            }
        }

        // If the credentials does not match with the admin credentials, send an "Access Forbidden" response message
        if (username.toString() != ADMIN_USERNAME || password.toString() != ADMIN_PASSWORD) {
            response.statusCode = 403;
            response.setJsonPayload({"Message":"Access Forbidden"});
            connection->respond(response) but { error e => log:printError("Error in responding ", err = e) };
        }

        // Construct and serialize the message to be published to the Kafka topic
        json priceUpdateInfo = {"Product":productName, "UpdatedPrice":newPriceAmount};
        blob serializedMsg = priceUpdateInfo.toString().toBlob("UTF-8");
        // Create the Kafka ProducerRecord and specify the destination topic - 'product-price' in this case
        // Set a valid partition number, which will be used when sending the record
        kafka:ProducerRecord record = {value:serializedMsg, topic:"product-price", partition:0};

        // Produce the message and publish it to the Kafka topic
        kafkaProduce(record);
        // Send a success status to the admin request
        response.setJsonPayload({"Status":"Success"});
        connection->respond(response) but { error e => log:printError("Error in responding ", err = e) };
    }
}

// Function to produce and publish a given record to a Kafka topic
function kafkaProduce (kafka:ProducerRecord record) {
    // Publish the record to the specified topic
    kafkaProducer->sendAdvanced(record);
    kafkaProducer->flush();
}
