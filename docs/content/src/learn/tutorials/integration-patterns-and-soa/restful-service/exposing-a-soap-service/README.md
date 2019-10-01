# RESTful Service  

REST (REpresentational State Transfer) is an architectural style for developing web services. It defines a set of constraints and properties based on HTTP. 

> In this guide you will learn about building a comprehensive RESTful Service using Ballerina.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build 
To understand how you can build a RESTful service using Ballerina, let’s consider an stock quote management scenario.
You can model this scenario as a RESTful service; 'stock_quote_service',  which accepts two different HTTP request for the tasks such as order creation and stock quote retrieval by connecting a SOAP backend from Ballerina.

- **Create Order** : To place a new order, use an HTTP POST request that contains order details, and then send the request to the Stock Quote service. If the request is successful, the service will respond with a 201 Created HTTP response with the location header pointing to the newly created resource.
- **Retrieve Order** : To retrieve sale price details of the stock, send an HTTP GET request with the stock symbol to the Stock Quote service.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

### Optional requirements
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping  "Implementation" section.

### Create the project structure

Let's use the following module structure for this project.

```
restful-service
 └── exposing-a-soap-service
      └── guide
           └── restful_service
                ├── stock_quote_service.bal
  	            └── tests
	                 └── stock_quote_service_test.bal
```

- Create the above directories in your local machine, along with the empty `.bal` files.

- Then open the terminal, navigate to restful-service/exposing-a-soap-service/guide, and run the Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the RESTful service

- You can start by defining a Ballerina HTTP service for the stock quote service `stockQuote`. The `stockQuote` service can comprise of multiple resources where each resource is responsible for a specific stock quote functionality.

You can add the following code segment to your `stock_quote_service.bal` file. It contains a service skeleton based on which you can build the stock quote service.
For each operation, there is a dedicated resource. You can implement the operation logic inside each resource.

##### Skeleton code for stock_quote_service.bal
```ballerina
import ballerina/http;

listener http:Listener httpListener = new(9090);

// The stock quote management is done using the SimpleStockQuoteService.
// Define a listener endpoint:
listener http:Listener httpListener = new(9090);

// RESTful service.
@http:ServiceConfig { basePath: "/stockQuote" }
service stockQuote on httpListener {

    // Resource that handles the HTTP GET requests that are directed to a specific
    // order using path '/order/<symbol>'
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/order/{symbol}"
    }
    resource function getQuote(http:Caller caller, http:Request request, string symbol) {
        // Implementation
    }

    // Resource that handles the HTTP POST requests that are directed to the path
    // '/order' to create a new order.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        // Implementation
    }
}
```

- You can implement the business logic of each resource depending on your requirements.
  Following is the full source code of the stock quote management service. Here, you will see how certain HTTP status codes and headers are manipulated whenever required in addition to the main logic.


##### stock_quote_service.bal
```ballerina
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
```

- With that you have completed the development of the order management service.


## Testing 
### Running the axis2 server
First run the axis2 server by following the [documentation]().

### Invoking the RESTful service 

You can run the RESTful service that you developed above, in your local environment. Open your terminal and navigate to `restful-service/exposing-a-soap-service/guide`, and execute the following command.
```bash
    $ ballerina run restful_service
```
Successful startup of the service results in the following output.
```
   Initiating service(s) in 'restful_service'
   [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```

To test the functionality of the stockQuote RESTFul service, send HTTP requests for each operation.
Following are sample cURL commands that you can use to test the operations.

**Create an order**
```bash
    $ curl -v -X POST -d \
    '<Order>
     	<Price>10.0</Price>
     	<Quantity>3</Quantity>
     	<Symbol>WSO2</Symbol>
     </Order>' \
    "http://localhost:9090/stockQuote/order" -H "Content-Type:application/xml"

    Output :  
    < HTTP/1.1 201 Created
    < Content-Type: application/xml
    < Location: http://localhost:9090/stockQuote/quote/WSO2
    < content-length: 202
    < server: ballerina/0.991.0
    
    <ns:placeOrderResponse xmlns:ns="http://services.samples">
        <ns:return xmlns:ax21="http://services.samples/xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ax21:placeOrderResponse">
            <ax21:status>Order has been created</ax21:status>
        </ns:return>
    </ns:placeOrderResponse>
```

**Retrieve quote of a stock**
```bash
    $ curl "http://localhost:9090/stockQuote/quote/WSO2"

    Output : 
    <ns:getQuoteResponse xmlns:ns="http://services.samples">
        <ns:return xmlns:ax21="http://services.samples/xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ax21:GetQuoteResponse">
            <ax21:change>3.8289830715883317</ax21:change>
            <ax21:earnings>13.199581261329985</ax21:earnings>
            <ax21:high>90.00732118602308</ax21:high>
            <ax21:last>86.65430450301076</ax21:last>
            <ax21:lastTradeTimestamp>Tue Jul 23 11:08:43 IST 2019</ax21:lastTradeTimestamp>
            <ax21:low>-85.87381815269296</ax21:low>
            <ax21:marketCap>5.7764274401095316E7</ax21:marketCap>
            <ax21:name>WSO2 Company</ax21:name>
            <ax21:open>89.63984815249187</ax21:open>
            <ax21:peRatio>23.477445115917355</ax21:peRatio>
            <ax21:percentageChange>4.092118238066442</ax21:percentageChange>
            <ax21:prevClose>93.5697076386912</ax21:prevClose>
            <ax21:symbol>WSO2</ax21:symbol>
            <ax21:volume>18053</ax21:volume>
        </ns:return>
    </ns:getQuoteResponse>
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same module inside a folder named as 'tests'. When writing the test functions, follow the convention given below.
- Test functions should be annotated with `@test:Config`. See the following example.
```ballerina
   @test:Config
   function testResourcePlaceOrder() {
```
  
The source code for this guide contains unit test cases for each resource available in the 'stockQuote' service implemented above.

To run the unit tests, open your terminal and navigate to `restful-service/exposing-a-soap-service/guide`, and run the following command.
```bash
    $ ballerina test
```

> The source code for the tests can be found at [stock_quote_service_test.bal](https://github.com/wso2/ballerina-integrator/tree/master/docs/learn/guides/services/restful-service/exposing-a-soap-service/guide/restful_service/tests/stock_quote_service_test.bal).


## Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below.

### Deploying locally

- As the first step, you can build a Ballerina executable archive (.balx) of the service that you developed. Navigate to `restful-service/exposing-a-soap-service/guide` and run the following command.
```bash
    $ ballerina build restful_service
```

- Once the restful_service.balx is created inside the target folder, you can run that with the following command.
```bash
    $ ballerina run target/restful_service.balx
```

- Successful startup of the service results in the following output.
```
   Initiating service(s) in 'target/restful_service.balx'
   [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
```


