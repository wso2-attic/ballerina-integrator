import ballerina/log;
import ballerina/http;
import ballerina/jms;


//Deploying on kubernetes

//import ballerinax/kubernetes;
// Other imports

// Type definition for a Deliver order

//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

//@kubernetes:Ingress {
//hostname:"ballerina.guides.io",
//name:"ballerina-guides-phone_order_delivery_service",
//path:"/"
//}

//@kubernetes:Service {
//serviceType:"NodePort",
//name:"ballerina-guides-phone_order_delivery_service"
//}

//@kubernetes:Deployment {
//image:"ballerina.guides.io/phone_store_service:v1.0",
//name:"ballerina-guides-phone_order_delivery_service"
//}

//endpoint http:Listener listener {
//port:9091
//};

//@http:ServiceConfig {basePath:"/phonestore1"}
//service<http:Service> phone_store_service bind listener {



//Deploying on docker

// import ballerinax/docker;
// Other imports

// Type definition for a  Deliver order

//json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

//@docker:Config {
//registry:"ballerina.guides.io",
//name:"phone_order_delivery_service",
//tag:"v1.0"
//}

// Service endpoint
//@docker:Expose{}
//endpoint http:Listener listener {
//port:9091
//};

// phone store service, which allows users to order phones online for delivery
//@http:ServiceConfig {basePath:"/phonestore1"}
//service<http:Service> phone_order_delivery_service bind listener {


type phoneDeliver record {
    string customerName;
    string address;
    string contactNumber;
    string deliveryPhoneName;
};


json[] phoneInventory = ["Apple:190000", "Samsung:150000", "Nokia:80000", "HTC:40000", "Huawei:100000"];

jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer2 {
    session:jmsSession,
    queueName:"DeliveryQueue"
};

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Service endpoint
endpoint http:Listener deliveryEP {
    port:9091
};

@http:ServiceConfig {basePath:"/deliveryDetails"}

// phone store service, which allows users to order phones online for delivery
service<http:Service> phone_order_delivery_service bind deliveryEP {
    // Resource that allows users to place an order for a phone
    @http:ResourceConfig { consumes: ["application/json"],
        produces: ["application/json"] }

    sendDelivery(endpoint caller, http:Request enrichedreq) {
        http:Response response;
        phoneDeliver newDeliver;
        json reqPayload;

        log:printInfo(" Order Details have received from phone_store_service");

        // Try parsing the JSON payload from the request
        match  enrichedreq.getJsonPayload() {
            // Valid JSON payload
            json payload => reqPayload = payload;
            // NOT a valid JSON payload
            any => {
                response.statusCode = 400;
                response.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = caller -> respond(response);
                done;
            }
        }

        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json phoneName = reqPayload.PhoneName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || phoneName == null) {
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid payload"});
            _ = caller -> respond(response);
            done;
        }

        // Order details
        newDeliver.customerName = name.toString();
        newDeliver.address = address.toString();
        newDeliver.contactNumber = contact.toString();
        newDeliver.deliveryPhoneName = phoneName.toString();

        // boolean variable to track the availability of a requested phone
        boolean isPhoneAvailable;
        // Check whether the requested phone available
        foreach phone in phoneInventory {
            if (newDeliver.deliveryPhoneName.equalsIgnoreCase(phone.toString())) {
                isPhoneAvailable = true;
                break;
            }
        }

        json responseMessage;
        // If the requested phone is available, then add the order to the 'OrderQueue'
        if (isPhoneAvailable) {
            var phoneDeliverDetails = check <json>newDeliver;
            // Create a JMS message

            jms:Message queueMessage2 = check jmsSession.createTextMessage(phoneDeliverDetails.toString());

            log:printInfo("order Delivery details  added to the delivery  Queue; CustomerName: '" + newDeliver.customerName +
                    "', OrderedPhone: '" + newDeliver.deliveryPhoneName + "';");

            // Send the message to the JMS queue
            _ = jmsProducer2 -> send(queueMessage2);

            // Construct a success message for the response
            responseMessage = {"Message":"Your order is successfully placed. Ordered phone will be delivered soon"};

        }
        else {
            // If phone is not available, construct a proper response message to notify user
            responseMessage = {"Message":"Requested phone not available"};
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = caller -> respond(response);
    }

}


jms:Connection conn = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession2 = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session


endpoint jms:QueueReceiver jmsConsumer2 {
    session:jmsSession2,
    queueName:"DeliveryQueue"
};


service<jms:Consumer> deliverySystem bind jmsConsumer2 {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message2) {
        log:printInfo("New order successfilly received from the Delivery Queue");
        // Retrieve the string payload using native function
        string stringPayload2 = check message2.getTextMessageContent();
        log:printInfo("Delivery Details: " + stringPayload2);

        log:printInfo(" Delivery Details sent to the customer successfully");


    }
}

