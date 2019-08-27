# RESTful Service Template

This template demonstrates how to build a comprehensive RESTful Service with SOAP back-end.

## How to run the template

### Initializing Ballerina
- Open the terminal from the created template and run the Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Running the axis2 server and deploying the back-end service
First run the axis2 server by following the [documentation](https://docs.wso2.com/display/EI650/Setting+Up+the+ESB+Samples#SettingUptheESBSamples-StartingtheAxis2server).

To deploy the back-end service SimpleStockQuoteService, run the ant command from the  <EI_HOME>/samples/axis2Server/src/SimpleStockQuoteService directory.

### Invoking the RESTful service 
First, alter the config file `src/hello_world_service/resources/ballerina.conf` as per the requirement.

To run the service, execute the following command.
```bash
    $ ballerina run restful_service --config src/restful_service/resources/ballerina.conf
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
