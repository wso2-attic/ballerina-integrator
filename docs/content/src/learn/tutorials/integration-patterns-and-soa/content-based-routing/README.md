# Content-Based Routing

## About

Content-based routing is an integration pattern where the message received from a client is routed to different channels/paths/endpoints based on the content of the message. This guide demonstrates a simple content-based routing scenario where, based on the company name provided in the request, the relevant company’s service endpoint is called to get the stock quote.

## What you'll build

We create a service called `stockQuote` that accepts an HTTP request from a client. The client appends as a query parameter in the request; i.e., the company name of which he wants to know the price of the stock. The `stockQuote` service identifies the company, routes the request to the relevant company’s stock quote service, obtains the response from the company’s service and returns the response to the client. If the company name is not available in the request, the service will simply respond with a 400 - Bad Request.

![cbr](../../../../assets/img/content_based_routing.jpg)

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina IDE plugin for [VS Code](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina)
	
## Implementation

* Create a new Ballerina project named `content-based-routing`.

    ```bash
    $ ballerina new content-based-routing
    ```

* Navigate to the content-based-routing directory.

* Add a new module named `stockquote_service` to the project.

    ```bash
    $ ballerina add stockquote_service
    ```

* Open the project with VS Code. The project structure will be similar to the following.

    ```shell
    .
    ├── Ballerina.toml
    └── src
        └── stockquote_service
            ├── main.bal
            ├── Module.md
            ├── resources
            └── tests
                ├── main_test.bal
                └── resources
    ```

We can remove the file `main_test.bal` for the moment, since we are not writing any tests for our service.

First let's create the services that we will use as backend endpoints.

* Create a new file named `abcService.bal` file under `stockquote_service` with the following content.

**abcService.bal**

<!-- INCLUDE_CODE: src/stockquote_service/abcService.bal -->

This is simply a service that will run on port 8081 responding a text payload `10000.00`.

* Likewise, let's create another file `xyzService.bal` with the following content.

**xyzService.bal**

<!-- INCLUDE_CODE: src/stockquote_service/xyzService.bal -->

* Now let's open the `main.bal` file and add the following content. This is going to be our integration logic.

**main.bal**

<!-- INCLUDE_CODE: src/stockquote_service/main.bal -->

Here we are calling the two services we created earlier using the endpoints `abcEP` and `xyzEP`.

In the stockQuote service, the `company` is retrieved as a query parameter. Then the value of the `company` is checked. If it is `abc`, the `abcEP` is called and its response is saved. If it is `xyz`, the `xyzEP` is called. If there is no value set, we’re simply setting a 400-Bad Request response. Finally the response is sent back to the client.

## Run the Integration

* First let’s build the module. While being in the content-based-routing directory, execute the following command.

    ```bash
    $ ballerina build stockquote_service
    ```

This would create the executables.

* Now run the .jar file created in the above step.

    ```bash
    $ java -jar target/bin/stockquote_service.jar
    ```

Now we can see that three service have started on ports 8081, 8082, and 9090. 

* Let’s access the stockQuote service by executing the following curl command.

    ```bash
    $ curl http://localhost:9090/stocktrading/stockquote?company=abc
    ```

We will get a text value 10000.00 as the response.
