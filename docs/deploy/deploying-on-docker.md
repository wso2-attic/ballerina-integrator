# Deploying on Docker

Deploying your Ballerina code is easier than ever with the growth of containers and container platforms such as Kubernetes.

Deploying a Ballerina program or service is the process of creating assets that ready the program and service(s) for activation in another runtime, such as Docker Engine, Moby, Kubernetes, or Cloud Foundry. The Ballerina compiler is able to generate the necessary artifacts for different deployment annotations based on annotations that decorate the source code, which provide compiler instructions for artifact generation.

> **Tip**: The `docker` command line tool needs to be installed and working. Try: `docker ps` to verify this. Go to the [install page](#https://get.docker.io/) if you need to install Docker.

## Creating a simple service

The following is a simple service that gets information from an endpoint.

```ballerina
import ballerina/http;
import ballerina/io;

// Creates a new client with the backend URL.
http:Client clientEndpoint = new("https://postman-echo.com");

public function main() {
    io:println("GET request:");
    // Sends a `GET` request to the specified endpoint.
    var response = clientEndpoint->get("/get?test=123");
    // Handles the response.
    handleResponse(response);

}
```

## Deploying your service on Docker

You can run the service that you developed above as a Docker container. The Ballerina language includes a [Ballerina_Docker_Extension](#https://github.com/ballerinax/docker) that offers native support to run Ballerina programs on containers.

To run a service as a Docker container, add the corresponding Docker annotations to your service code.

See the following example on how you can add Docker support in the code.

To add Docker support, add the following code to the service you created above.

```ballerina
import ballerina/http;  
import ballerinax/docker;  
  
@http:ServiceConfig {  
    basePath:"/helloWorld"  
}  
@docker:Config {
    registry:"docker.abc.com",
    name:"helloworld",
    tag:"v1.0"
}
service helloWorld on new http:Listener(9090) {
    resource function sayHello (http:Caller caller, http:Request request) {
        http:Response response = new;
        response.setTextPayload("Hello, World! \n");
        _ = caller -> respond(response);
    }
}
```

Now your code is ready to generate deployment artifacts. In this case it is a Docker image.
  
```bash
$ ballerina build hello_world_docker.bal  
Compiling source
    hello_world_docker.bal

Generating executable
    ./target/hello_world_docker.balx
	@docker 		 - complete 3/3

	Run the following command to start a Docker container:
	docker run -d -p 9090:9090 docker.abc.com/helloworld:v1.0
```
  
```bash
$ tree  
.
├── hello_world_docker.bal
├── hello_world_docker.balx
└── docker
    └── Dockerfile
```
```bash
$ docker images  
REPOSITORY                TAG IMAGE ID       CREATED             SIZE  
docker.abc.com/helloworld  v1 df83ae43f69b   2 minutes ago       102MB
```
  
You can run a Docker container by copying and pasting the Docker `run` command that displays as output of the Ballerina `build` command.
```bash
$ docker run -d -p 9090:9090 docker.abc.com/helloworld:v1.0  
130ded2ae413d0c37021f2026f3a36ed92e993c39c260815e3aa5993d947dd00
```

```bash
$ docker ps  
CONTAINER ID  IMAGE                          COMMAND                CREATED                STATUS       PORTS                  NAMES  
130ded2ae413  docker.abc.com/helloworld:v1.0 "/bin/sh -c 'balleri…" Less than a second ago Up 3 seconds 0.0.0.0:9090->9090/tcp thirsty_hopper
```
Invoke the hello world service with a cURL command:
```bash 
$ curl http://localhost:9090/helloWorld/sayHello  
Hello, World!
```
