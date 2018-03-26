# RESTful Service  

In this guide you will learn about building a comprehensive RESTful Web Service using Ballerina. 

## <a name="what-you-build"></a> What you’ll build 
To understanding how you can build a RESTful web service using Ballerina, let’s consider a real world use case of an order management scenario of an online retail application. 
We can model the order management scenario as a RESTful web service; 'OrderMgtService',  which accepts different HTTP request for order management tasks such as order creation, retrieval, updating and deletion.
The following figure illustrates all the required functionalities of the OrderMgt RESTful web service that we need to build. 

![RESTful Service](images/restful_service.png "RESTful Service")

- **Create Order** : To place a new order you can use the HTTP POST message that contains the order details, which is sent to the URL `http://xyz.retail.com/order`.The response from the service contains an HTTP 201 Created message with the location header pointing to the newly created resource `http://xyz.retail.com/order/123456`. 
- **Retrieve Order** : You can retrieve the order details by sending an HTTP GET request to the appropriate URL which includes the order ID.`http://xyz.retail.com/order/<orderId>` 
- **Update Order** : You can update an existing order by sending a HTTP PUT request with the content for the updated order. 
- **Delete Order** : An existing order can be deleted by sending a HTTP DELETE request to the specific URL`http://xyz.retail.com/order/<orderId>`. 

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- A Text Editor or an IDE. 

Optional Requirements
- Ballerina IDE plugins. ( Intellij IDEA, VSCode, Atom)

## <a name="developing-service"></a> Developing the RESTFul service 

We can model the OrderMgt RESTful service using Ballerina services and resources constructs. 

1. We can get started with a Ballerina service; 'OrderMgtService', which is the RESTful service that serves the order management request. OrderMgtService can have multiple resources and each resource is dedicated for a specific order management functionality.
2. You can decide the package structure for the service and then create the service in the corresponding directory structure. For example, suppose that you are going to use the package name 'restfulService', then you need to create the following directory structure and create the service file using the text editor or IDE that you use. 

```
restful-service
  └── restfulService
      ├── OrderMgtService.bal
      └── tests
          └── OrderMgtService_test.bal
          
```
2. You can add the content to your Ballerina service as shown below. In that code segment you can find the implementation of the service and resource skeletons of 'OrderMgtService'. 
For each order management operation, there is a dedicated resource and inside each resource we can implement the order management operation logic. 

##### OrderMgtService.bal
```ballerina
package restfulService;

import ballerina/net.http;

endpoint http:ServiceEndpoint orderMgtServiceEP {
    port:9090
};

@Description {value:"RESTful service."}
@http:ServiceConfig {basePath:"/ordermgt"}
service<http:Service> OrderMgtService bind orderMgtServiceEP {
    
    // Order management is done using an in memory orders map.
    // Add some sample orders to the orderMap during the startup.
    map ordersMap = {};

    @Description {value:"Resource that handles the HTTP GET requests that are directed to a specific order using path '/orders/<orderID>'"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    findOrder (endpoint client, http:Request req, string orderId) {
        // Implementation 
    }


    @Description {value:"Resource that handles the HTTP POST requests that are directed to the path '/orders' to create a new Order."}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order"
    }
    addOrder (endpoint client, http:Request req) {
        // Implementation 
    }

    @Description {value:"Resource that handles the HTTP PUT requests that are directed to the path '/orders' to update an existing Order."}
    @http:ResourceConfig {
        methods:["PUT"],
        path:"/order/{orderId}"
    }
    updateOrder (endpoint client, http:Request req, string orderId) {
        // Implementation 
    }

    @Description {value:"Resource that handles the HTTP DELETE requests that are directed to the path '/orders/<orderId>' to delete an existing Order."}
    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/order/{orderId}"
    }
    cancelOrder (endpoint client, http:Request req, string orderId) {
        // Implementation    
    }
}


```

3. You can implement the business logic of each resources as per your requirements. For simplicity we have used an in-memory map to keep all the order details. You can find the full source code of the OrderMgtService below. In addition to the order processing logic, we have also manipulated some HTTP status codes and headers whenever required.  


##### OrderMgtService.bal
```ballerina
package restfulService;

import ballerina/net.http;

endpoint http:ServiceEndpoint orderMgtServiceEP {
    port:9090
};

@Description {value:"RESTful service."}
@http:ServiceConfig {basePath:"/ordermgt"}
service<http:Service> OrderMgtService bind orderMgtServiceEP {

    // Order management is done using an in memory orders map.
    // Add some sample orders to the orderMap during the startup.
    map<json> ordersMap = {};
    @Description {value:"Resource that handles the HTTP GET requests that are directed to a specific order using path '/orders/<orderID>'"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    findOrder (endpoint client, http:Request req, string orderId) {
        // Find the requested order from the map and retrieve it in JSON format.
        json payload = ordersMap[orderId];
        http:Response response = {};
        if (payload == null) {
            payload = "Order : " + orderId + " cannot be found.";
        }

        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = client -> respond(response);
    }

    @Description {value:"Resource that handles the HTTP POST requests that are directed to the path '/orders' to create a new Order."}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order"
    }
    addOrder (endpoint client, http:Request req) {
        json orderReq =? req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;

        // Create response message
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response = {};
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message
        response.statusCode = 201;
        // Set 'Location' header in the response message. This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" + orderId);

        // Send response to the client
        _ = client -> respond(response);
    }

    @Description {value:"Resource that handles the HTTP PUT requests that are directed to the path '/orders' to update an existing Order."}
    @http:ResourceConfig {
        methods:["PUT"],
        path:"/order/{orderId}"
    }
    updateOrder (endpoint client, http:Request req, string orderId) {
        json updatedOrder =? req.getJsonPayload();

        // Find the order that needs to be updated from the map and retrieve it in JSON format.
        json existingOrder = ordersMap[orderId];

        // Updating existing order with the attributes of the updated order
        if (existingOrder != null) {
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;
        } else {
            existingOrder = "Order : " + orderId + " cannot be found.";
        }

        http:Response response = {};
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(existingOrder);
        // Send response to the client
        _ = client -> forward(response);
    }


    @Description {value:"Resource that handles the HTTP DELETE requests that are directed to the path '/orders/<orderId>' to delete an existing Order."}
    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/order/{orderId}"
    }
    cancelOrder (endpoint client, http:Request req, string orderId) {
        http:Response response = {};
        // Remove the requested order from the map.
        _ = ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = client -> respond(response);
    }

}

```

4. With that we've completed the development of OrderMgtService. 


## <a name="testing"></a> Testing 

### <a name="invoking"></a> Invoking the RESTful service 

You can run the RESTful service that you developed above, in your local environment. You need to have the Ballerina installation in you local machine and simply point to the <ballerina>/bin/ballerina binary to execute all the following steps.  

1. As the first step you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. Navigate to the `<SAMPLE_ROOT>/restfulService/` folder and run the following command. 

```
$ballerina build OrderMgtService.bal
```

2. Once the restful_service.balx is created, you can run that with the following command. 

```
$ballerina run OrderMgtService.balx 
```

3. The successful execution of the service should show us the following output. 
```
$ballerina run OrderMgtService.balx 
ballerina: deploying service(s) in 'OrderMgtService.balx'
Sample orders are added.
 
```

4. You can test the functionality of the OrderMgt RESTFul service by sending HTTP request for each order management operation. For example, we have used the curl commands to test each operation of OrderMgtService as follows. 

**Create Order** 
```
curl -v -X POST -d '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
 "http://localhost:9090/ordermgt/order" -H "Content-Type:application/json"

Output :  
< HTTP/1.1 201 Created
< Content-Type: application/json
< Location: http://localhost:9090/ordermgt/order/100500
< Transfer-Encoding: chunked
< Server: wso2-http-transport

{"status":"Order Created.","orderId":"100500"}
 
```

**Retrieve Order** 
```
curl "http://localhost:9090/ordermgt/order/100500" 

Output : 
{"Order":{"ID":"100500","Name":"XYZ","Description":"Sample order."}}


```
**Update Order** 
```
curl -X PUT -d '{ "Order": {"Name": "XYZ", "Description": "Updated order."}}' \
 "http://localhost:9090/ordermgt/order/100500" -H "Content-Type:application/json"

Output: 
{"Order":{"ID":"100500","Name":"XYZ","Description":"Updated order."}}
```

**Cancel Order** 
```
curl -X DELETE "http://localhost:9090/ordermgt/order/100500"

Output:
"Order : 100500 removed."
```

### <a name="unit-testing"></a> Writing Unit Tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. The naming convention should be as follows,

* Test functions should contain test prefix.
  * e.g.: testResourceAddOrder()

This guide contains unit test cases for each resource available in 'OrderMgtService'.

To run the unit tests, go to the sample root directory and run the following command.
   ```bash
   $ballerina test restfulService/
   ```

To check the implementation of the test file, refer to the [OrderMgtService_test.bal](https://github.com/ballerina-guides/restful-service/blob/master/restfulService/OrderMgtService_test.bal).


## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying Locally
You can deploy the RESTful service that you developed above, in your local environment. You can use the Ballerina executable archive (.balx) archive that we created above and run it in your local environment as follows. 

```
$ballerina run OrderMgtService.balx 
```

### <a name="deploying-on-docker"></a> Deploying on Docker


You can run the service that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on 
containers, you just need to put the corresponding docker annotations on your service code. 

- In our OrderMgtService, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### OrderMgtService.bal
```ballerina
    package restfulService;
    
    import ballerina/net.http;
    import ballerinax/docker;
    
    endpoint http:ServiceEndpoint orderMgtServiceEP {
        port:9090
    };
    
    @docker:Config {
        registry:"docker.abc.com",
        name:"restful-ordermgt-service",
        tag:"v1.0"
    }
    
   @http:ServiceConfig {
        basePath:"/ordermgt"
   }
   service<http:Service> OrderMgtService bind orderMgtServiceEP {
   
``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/restfulService/` folder and run the following command.  
  
  ```
  $ballerina build OrderMgtService.bal
  
  Run following command to start docker container: 
  docker run -d -p 9090:9090 docker.abc.com/restful-ordermgt-service:v1.0
  ```
- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

    ```   
    docker run -d -p 9090:9090 docker.abc.com/restful-ordermgt-service:v1.0
    ```
    Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we  use  the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl commands that we've used above. 
 
    ```
    curl -v -X POST -d '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
     "http://localhost:9090/ordermgt/order" -H "Content-Type:application/json"    
    ```


### <a name="deploying-on-k8s"></a> Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, 
with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. 
So you don't need to explicitly create docker images prior to deploying it on Kubernetes.   

- In our OrderMgtService, we need to import  `` import ballerinax/kubernetes; `` and use `` @kubernetes `` as shown below to enable docker 
image generation during the build time. 

##### OrderMgtService.bal

```ballerina
    package restfulService;
    
    import ballerina/net.http;
    import ballerinax/kubernetes;
    
    endpoint http:ServiceEndpoint orderMgtServiceEP {
        port:9090
    };
    
    @kubernetes:deployment {
        image:"ballerina.com/order-mgt-service:1.0.0"
    }
    @kubernetes:svc {}
    @kubernetes :ingress {
        hostname:"ordermgt.com",
        path:"/"
    }
    
   @http:ServiceConfig {
        basePath:"/ordermgt"
   }
   service<http:Service> OrderMgtService bind orderMgtServiceEP {
        
``` 
- Here we have used ``  @kubernetes:deployment `` to specify the docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:svc {} `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes :ingress `` which is the external interface to access your service (with path `` /`` and host name `` ordermgt.com``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
  ```
  $ballerina build OrderMgtService.bal
  Run following command to deploy kubernetes artifacts:  
  kubectl create -f ./target/restfulService/kubernetes
 
  ```

- You can verify that the docker image that we specified in `` @kubernetes:deployment `` is created, by using `` docker ps images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/restfulService/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
 $ kubectl create -f ./target/restfulService/kubernetes 
     deployment "OrderMgtService-deployment" created
     ingress "OrderMgtService" created
     service "OrderMgtService" created
```
- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 
```
$kubectl get svc
$kubectl get deploy
$kubectl get pods
$kubectl get ingress

```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
curl -v -X POST -d '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
        "http://localhost:<Node_Port>/ordermgt/order" -H "Content-Type:application/json"    
```
Ingress:

Add /etc/host entry to match hostname. 
``` 
127.0.0.1 ordermgt.com
```

Access the service 

``` 
curl -v -X POST -d '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
     "http://ordermgt.com/ordermgt/order" -H "Content-Type:application/json" 
    
```


## <a name="observability"></a> Observability 

### <a name="logging"></a> Logging
(Work in progress) 

### <a name="metrics"></a> Metrics
(Work in progress) 


### <a name="tracing"></a> Tracing 
(Work in progress) 
