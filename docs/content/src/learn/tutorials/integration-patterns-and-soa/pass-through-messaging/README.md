# Pass-Through Messaging

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors.

There are different messaging methods in SOA (Service Oriented Architecture). In this guide, we are focusing on pass-through messaging between services using an example scenario.

## What you’ll build

There are different ways of messaging between services such as pass-through messaging, content-based routing of messages, header-based routing of messages, and scatter-gather messaging. There is a delay in messaging while processing an incoming message in all messaging methods excluding pass-through messaging. When routing the message without processing/inspecting the message payload, the most efficient way is the pass-through messaging. Here are some differences between conventional message processing vs pass-through messaging.

![alt text](../../../../assets/img/pass-through-messaging-1.svg)

Conventional message processing methods include a message processor for processing messages, but pass-through messaging skipped the message processor. It thereby saves the processing time and power and is more efficient when compared to other types.

Now let's understand the scenario described here. The owner needs to expand the business, so he makes online shop that is connected to the local shop, to expand the business. When you connect to the online shop, it will automatically be redirected to the local shop without any latency. To do so, the pass-through messaging method is used.

![alt text](../../../../assets/img/pass-through-messaging-2.svg	)

The two shops are implemented as two separate services named as 'OnlineShopping' and 'LocalShop'. When a user makes a call to 'OnlineShopping' using an HTTP request, the request is redirected to the 'LocalShop' service without processing the incoming request. Also the response from the 'LocalShop' is not be processed in 'OnlineShopping'. If it processes the incoming request or response from the 'LocalShop', it will no longer be a pass-through messaging method. 

So, messaging between 'OnlineShopping' and 'LocalShop' services act as pass-through messaging. The 'LocalShop' service processes the incoming request method such as 'GET' and 'POST'. Then it calls the back-end service, which will give the "Welcome to Local Shop! Please put your order here....." message. So messaging in the 'LocalShop' service is not a pass-through messaging service.

<!-- INCLUDE_MD: ../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../tutorial-get-the-code.md -->

## Implementation

> If you are well aware of the implementation, you can directly clone the GitHub repository to your own device. Using that, you can skip the "Implementation" section and move straight to the "Testing" section.

1. Create a project.
```bash
$ ballerina new pass-through-messaging
```

 2. Navigate into the project directory and add a new module.
```bash
$ ballerina add pass_through_messaging
```

3. Add .bal files with meaningful names as shown in the project structure given below.
```
pass-through-messaging
 ├── Ballerina.toml
 └── src
     └── pass_through_messaging
         ├── resources
         ├── Module.md
         ├── pass_through.bal
         └── tests
             ├── resources
             └── pass_through_test.bal
```

### Developing the service

To implement the scenario, let's start by implementing the pass_through.bal file, which is the main file in the implementation.

#### pass_through.bal file
```ballerina
import ballerina/http;
import ballerina/log;

listener http:Listener OnlineShoppingEP = new(9090);
listener http:Listener LocalShopEP = new(9091);

//Defines a client endpoint for the local shop with online shop link.
http:Client clientEP = new("http://localhost:9091/LocalShop");

//This is a passthrough service.
service OnlineShopping on OnlineShoppingEP {
    //This resource allows all HTTP methods.
    @http:ResourceConfig {
        path: "/"
    }
    resource function passthrough(http:Caller caller, http:Request req) {
        log:printInfo("Request will be forwarded to Local Shop  .......");
        //'forward()' sends the incoming request unaltered to the backend. Forward function
        //uses the same HTTP method as in the incoming request.
        var clientResponse = clientEP->forward("/", req);
        if (clientResponse is http:Response) {
            //Sends the client response to the caller.
            var result = caller->respond(clientResponse);
            handleError(result);
        } else {
            //Sends the error response to the caller.
            http:Response res = new;
            res.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            res.setPayload(<string>clientResponse.detail()?.message);
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
```

`forward()` function seen below sends the incoming request unaltered to the backend. It uses the same HTTP method as in the incoming request.
```ballerina
var clientResponse = clientEP->forward("/", req);
```

## Testing 

### Invoking the service

Let’s build the module. Navigate to the project directory and execute the following command.
```
$ ballerina build pass_through_messaging
```

The build command would create an executable .jar file. Now run the .jar file created in the above step using the following command.
```
$ java -jar target/bin/pass_through_messaging.jar
```

**Send a request to the online shopping service**
```bash
$ curl -v http://localhost:9090/OnlineShopping
```
**Output**

```bash
< HTTP/1.1 200 OK
< content-type: text/plain
< date: Sat, 23 Jun 2018 05:45:17 +0530
< server: ballerina/0.982.0
< content-length: 54
< 
* Connection #0 to host localhost left intact
Welcome to Local Shop! Please put your order here.....
```

To identify the message flow inside the services, there will be INFO in the notification channel.

```bash
2018-06-23 05:45:27,849 INFO  [pass_through_messaging] - Request will be forwarded to Local Shop  .......
2018-06-23 05:45:27,864 INFO  [pass_through_messaging] - You have been successfully connected to local shop  .......
```
