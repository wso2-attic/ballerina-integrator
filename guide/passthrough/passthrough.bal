import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
//import ballerinax/kubernetes;



//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"passthrough",
//    path:"/"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"OnlineShopping"
//}
//
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/passthrough:v1.0",
//    name: "ballerina-guides-passt-hrough-messaging"
//}

//@docker:Expose {}
<<<<<<< HEAD
listener http:Listener OnlineShoppingEP = new(9090);
=======
endpoint http:Listener OnlineShoppingEP {
    port: 9090
};
>>>>>>> c5694e812c342dad6d1cc279c5b81d3706ca9bc7

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"LocalShop"
//}
//@docker:Expose {}
<<<<<<< HEAD
listener http:Listener LocalShopEP = new(9091);

//Defines a client endpoint for the local shop with online shop link.
http:Client clientEP = new("http://localhost:9091/LocalShop");

=======
endpoint http:Listener LocalShopEP {
    port: 9091
};


//Define end-point for the local shop as online shop link
endpoint http:Client clientEP {
    url: "http://localhost:9091/LocalShop"
};

>>>>>>> c5694e812c342dad6d1cc279c5b81d3706ca9bc7
//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"passthrough",
//    tag:"v1.0"
//}

//This is a passthrough service.
service OnlineShopping on OnlineShoppingEP {
    //This resource allows all HTTP methods.
    @http:ResourceConfig {
        path: "/"
    }
<<<<<<< HEAD
    resource function passthrough(http:Caller caller, http:Request req) {
        log:printInfo("Request will be forwarded to Local Shop  .......");
        //'Forward()' sends the incoming request unaltered to the backend. Forward function
        //uses the same HTTP method as in the incoming request.
=======
    passthrough(endpoint caller, http:Request req) {
        // set log message as "the request will be directed to another service" in pass-through method.
        log:printInfo("You will be redirected to Local Shop  .......");
        //'Forward()' used to call the backend endpoint created above as pass-through method. In forward function,
        //it used the same HTTP method, which used to invoke the primary service.
        // The `forward()` function returns the response from the backend if there are no errors.
>>>>>>> c5694e812c342dad6d1cc279c5b81d3706ca9bc7
        var clientResponse = clientEP->forward("/", req);

        if (clientResponse is http:Response) {
            //Sends the client response to the caller.
            var result = caller->respond(clientResponse);
            handleError(result);
        } else if (clientResponse is error) {
            //Sends the error response to the caller.
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(string.create(clientResponse.detail().message));
            var result = caller->respond(res);
            handleError(result);
        }
    }
}

//Sample Local Shop service.
service LocalShop on LocalShopEP {
    //The LocalShop only accepts requests made using the specified HTTP methods.
    @http:ResourceConfig {
        methods: ["POST", "GET"],
        path: "/"
    }
    resource function helloResource(http:Caller caller, http:Request req) {
        log:printInfo("You have been successfully connected to local shop  .......");
        // Make the response for the request.
        http:Response res = new;
        res.setPayload("Welcome to Local Shop! Please put your order here.....");
        //Sends the response to the caller.
        var result = caller->respond(res);
        handleError(result);
    }
}

function handleError(error? result) {
    if (result is error) {
        log:printError(result.reason(), err = result);
    }
}
