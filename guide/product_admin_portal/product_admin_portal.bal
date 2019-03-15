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
import ballerinax/kubernetes;

// Constants to store admin credentials
final string ADMIN_USERNAME = "Admin";
final string ADMIN_PASSWORD = "Admin";

// Kafka producer configurations
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "basic-producer",
    acks: "all",
    noRetries: 3
};

kafka:SimpleProducer kafkaProducer = new(producerConfigs);

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-product-admin-portal",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-product-admin-portal"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/product_admin_portal:v1.0",
    name:"ballerina-guides-product-admin-portal",
    copyFiles:[{target:"/ballerina/runtime/bre/lib",
        source:<path_to_kafka_connector_jars>}],
    username:"<USERNAME>",
    password:"<PASSWORD>",
    push:true,
    imagePullPolicy:"Always"
}

// HTTP service endpoint
listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/product" }
service productAdminService on httpListener {

    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    resource function updatePrice(http:Caller caller, http:Request request) {
        http:Response response = new;
        float newPriceAmount = 0.0;
        json|error reqPayload = request.getJsonPayload();

        if (reqPayload is error) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            _ = caller->respond(response);
        } else {
            json username = reqPayload.Username;
            json password = reqPayload.Password;
            json productName = reqPayload.Product;
            json newPrice = reqPayload.Price;

            // If payload parsing fails, send a "Bad Request" message as the response
            if (username == null || password == null || productName == null || newPrice == null) {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Bad Request: Invalid payload" });
                _ = caller->respond(response);
            }

            // Convert the price value to float
            var result = float.convert(newPrice.toString());
            if (result is error) {
                response.statusCode = 400;
                response.setJsonPayload({ "Message": "Invalid amount specified" });
                _ = caller->respond(response);
            } else {
                newPriceAmount = result;
            }

            // If the credentials does not match with the admin credentials,
            // send an "Access Forbidden" response message
            if (username.toString() != ADMIN_USERNAME || password.toString() != ADMIN_PASSWORD) {
                response.statusCode = 403;
                response.setJsonPayload({ "Message": "Access Forbidden" });
                _ = caller->respond(response);
            }

            // Construct and serialize the message to be published to the Kafka topic
            json priceUpdateInfo = { "Product": productName, "UpdatedPrice": newPriceAmount };
            byte[] serializedMsg = priceUpdateInfo.toString().toByteArray("UTF-8");

            // Produce the message and publish it to the Kafka topic
            var sendResult = kafkaProducer->send(serializedMsg, "product-price", partition = 0);
            // Send internal server error if the sending has failed
            if (sendResult is error) {
                response.statusCode = 500;
                response.setJsonPayload({ "Message": "Kafka producer failed to send data" });
                _ = caller->respond(response);
            }
            // Send a success status to the admin request
            response.setJsonPayload({ "Status": "Success" });
            _ = caller->respond(response);
        }
    }
}
