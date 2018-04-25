# Asynchronous Invocations
[Asynchronous invocations](https://en.wikipedia.org/wiki/Asynchronous_method_invocation) or the asynchronous pattern is a design pattern in which the call site is not blocked while waiting for the called code to finish. Instead, the calling thread can use the result when the reply arrives.

> In this guide you will learn about building a web service with asynchronous RESTful calls. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build 

To understanding how you can use asynchronous invocations with Ballerina, let’s consider an Stock Quote Summary service.

- The Stock Quote Summary service will call a remote backend to get the stock data
- The Ballerina Stock Quote Summary service will call the remote backend for three separate endpoints asynchronously
- Finally, the quote summary servie will append all the results from three backend and send the responses to the client.

The following figure illustrates the scenario of the Stock Quote Summary service with asynchronous invocations. 


&nbsp;
&nbsp;
&nbsp;
&nbsp;

![async invocation](images/asynchronous-invocation.png "Asynchronous Invocation")

&nbsp;
&nbsp;
&nbsp;
&nbsp;



- **Request Stock Summary** : You can send HTTP GET request to the URL `http://localhost:9090/quote-summary` and retrieve the stock quote summary.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service 

> If you want to skip the basics, you can download the git repo and directly move to "Testing" section by skipping "Developing" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
asynchronous-invocation
  ├── stock_quote_summary_service
  │   └── async_service.bal
  └── stock_quote_data_backend
    └── stock_backend.bal
```
You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `asynchronous-invocation` and navigate to the directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
restful-service$ ballerina init -i
Create Ballerina.toml [yes/y, no/n]: (y) y
Organization name: (username) asynchronous-invocation
Version: (0.0.1) 
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) stock_quote_summary_service
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) stock_quote_data_backend
Ballerina source [service/s, main/m, finish/f]: (f) f

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change the names of the file to match with our guide project file names.
  
### Implement the stock quote summary service with asyncronous invocations

- We can get started with the stock quote summary service, which is the RESTful service that serves the stock quote summary requests. This service will reveive the requests as HTTP GET method from the clients.

-  The stock quote summary service will call three separate remote resorces asynchronously.

- The Ballerina language support function calls and client connector actions to execute asynchronously.`start` keyword allows you to invoke the function asychronously. The `future` type allows you to have the result in future. The program can proceed without any blocking after the asynchronous function invocation. The following statement will call the endpoint asynchronously.

  `future <http:Response|http:HttpConnectorError> responseFuture = start nasdaqServiceEP -> get("/nasdaq/quote/MSFT", request = req);`

- Finally, the service will append all three responses ard return the stock quote summary to the client. For get the results from a asynchronous call we need to use keywork `await`. `await` blocks until the previously started asynchronous invocation.
The following statement will get the response from the future type.

  ` var response1 = check await f1;`

##### async_service.bal
```ballerina
import ballerina/http;
import ballerina/io;
import ballerina/runtime;

@Description {value:"Attributes associated with the service endpoint is defined here."}
endpoint http:Listener asyncServiceEP {
    port:9090
};

@Description {value:"Service is to be exposed via HTTP/1.1."}
@http:ServiceConfig {
    basePath:"/quote-summary"
}
service<http:Service> AsyncInvoker bind asyncServiceEP {

    @Description {value:"Resource for the GET requests of quote service"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    getQuote(endpoint caller, http:Request req) {
        // Endpoint for the stock quote backend service
        endpoint http:Client nasdaqServiceEP {
            url:"http://localhost:9095"
        };
        http:Request req = new;
        http:Response resp = new;
        string responseStr;
        // Initialize empty json to add results from backed call
        json  responseJson = {};

        io:println(" >> Invoking services asynchrnounsly...");

        // 'start' allows you to invoke a functions  asynchronously. Following three
        // remote invocation returns without waiting for response.

        // Calling the backend to get the stock quote for GOOG asynchronously
        future <http:Response|http:HttpConnectorError> f1 = start nasdaqServiceEP
        -> get("/nasdaq/quote/GOOG", request = req);

        io:println(" >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for APPL asynchronously
        future <http:Response|http:HttpConnectorError> f2 = start nasdaqServiceEP
        -> get("/nasdaq/quote/APPL", request = req);

        io:println(" >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.");
        req = new;

        // Calling the backend to get the stock quote for MSFT asynchronously
        future <http:Response|http:HttpConnectorError> f3 = start nasdaqServiceEP
        -> get("/nasdaq/quote/MSFT", request = req);

        io:println(" >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.");

        // ‘await` blocks until the previously started async function returns.
        // Append the results from all the responses of stock data backend
        var response1 = await f1;
        // Use `match` to check the responses are available, if not available get error
        match response1 {
            http:Response resp => {

                responseStr = check resp.getStringPayload();
                // Add the response from /GOOG endpoint to responseJson file
                responseJson["GOOG"] = responseStr;
            }
            http:HttpConnectorError err => {
                io:println(err.message);
                responseStr = err.message;
            }
        }

        var response2 = await f2;
        match response2 {
            http:Response resp => {
                responseStr = check resp.getStringPayload();
                // Add the response from /APPL endpoint to responseJson file
                responseJson["APPL"] = responseStr;
            }
            http:HttpConnectorError err => {
                io:println(err.message);
            }
        }

        var response3 = await f3;
        match response3 {
            http:Response resp => {
                responseStr = check resp.getStringPayload();
                // Add the response from /MSFT endpoint to responseJson file
                responseJson["MSFT"] = responseStr;

            }
            http:HttpConnectorError err => {
                io:println(err.message);
            }
        }

        // Send the response back to the client
        resp.setJsonPayload(responseJson);
        io:println(" >> Response : " + responseJson.toString());
        _ = caller -> respond(resp);
    }
}
```

### Mock remote service: stock_quote_data_backend

You can use any third-party remote service for the remote backend service. For ease of explanation we have developed the mock stock quote remote backend with Ballerina. This mock stock data backend will have the following resources and respective responses
 - resource path `/GOOG` with response `"GOOG, Alphabet Inc., 1013.41"` 
 - resource path `/APPL` with response `"APPL, Apple Inc., 165.22"` 
 - resource path `/MSFT` with response `"MSFT, Microsoft Corporation, 95.35"` 

NOTE: You can find the complete implementaion of stock_quote_data_backend [here](stock_quote_data_backend/stock_backend.bal)


## Testing 

### Invoking stock quote summary service

- First, you need to run `stock_quote_data_backend`. Navigate to <SAMPLE_ROOT> directory and run the following command in the terminal.
```
$ballerina run stock_quote_data_backend/
```
NOTE: You need to have the Ballerina installed in you local machine to run the Ballerina service.

- Then, you need to run `stock_quote_summary_service`. Navigate to <SAMPLE_ROOT> directory and run the following command in the terminal.
```
$ballerina run stock_quote_summary_service/
```

- Now you can execute the following curl commands to call stock quote summary service

**Get stock quote summary for GOOG, APPL and MSFT** 

```
curl http://localhost:9090/quote-summary
```

```
Output :  
{
    "GOOG": "GOOG, Alphabet Inc., 1013.41",
    "APPL": "APPL, Apple Inc., 165.22",
    "MSFT": "MSFT, Microsoft Corporation, 95.35"
}
```

**Console output for stock_quote_summary_service(with asynchronous calls)**
```
 >> Invoking services asynchrnounsly...
 >> Invocation completed for GOOG stock quote! Proceed without
        blocking for a response.
 >> Invocation completed for APPL stock quote! Proceed without
        blocking for a response.
 >> Invocation completed for MSFT stock quote! Proceed without
        blocking for a response.
 >> Response : {
    "GOOG": "GOOG, Alphabet Inc., 1013.41",
    "APPL": "APPL, Apple Inc., 165.22",
    "MSFT": "MSFT, Microsoft Corporation, 95.35"
}
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'. The naming convention should be as follows,

* Test functions should contain test prefix.
  * e.g.: testResourceAddOrder()

To run the unit tests you run the following command.
```bash
   $ballerina test
```

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally

- As the first step you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory in which the service we developed above located and it will create an executable binary out of that. Navigate to the `<SAMPLE_ROOT>/` folder and run the following commands. 

```
$ballerina build stock_quote_summary_service
```

```
$ballerina build stock_quote_data_backend
```

- Once the stock_quote_summary_service.balx and build stock_quote_data_backend.balx are created inside the target folder, you can run that with the following command. 

```
$ballerina run target/stock_quote_summary_service.balx
```

```
$ballerina run target/stock_quote_data_backend.balx
```

- The successful execution of the service should show us the following output. 
```
$ballerina run target/stock_quote_summary_service.balx
ballerina: initiating service(s) in 'async_service.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

```
$ballerina run target/stock_quote_data_backend.balx
ballerina: initiating service(s) in 'stock_backend.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9095

```
