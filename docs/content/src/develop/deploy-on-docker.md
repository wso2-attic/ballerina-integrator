# Deploying on Docker

Deploying your Ballerina code is easier than ever with the growth of containers and container platforms such as Kubernetes.

Deploying a Ballerina integration service is the process of creating assets that ready the program and service(s) for activation in another runtime, such as Docker Engine, Moby, Kubernetes, or Cloud Foundry. The Ballerina compiler is able to generate the necessary artifacts for different deployment annotations based on annotations that decorate the source code, which provide compiler instructions for artifact generation.

This topic provides instructions on how to deploy your project on [Docker](https://www.docker.com/). The project in this case, is the same one you used in the [Quick Start Guide](../../getting-started/quick-start-guide/).

> **Tip**: The `docker` command line tool needs to be installed and working. Try: `docker ps` to verify this. Go to the [install page](https://get.docker.com/) if you need to install Docker.

## Set up the project 

1. Open VS Code.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already. Find the extension for Ballerina in the VS Code marketplace if you do not have it. This extension is called `Ballerina`. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

2. Press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

Select the template to transform XML messages to JSON and your project will load.

## Deploying your service on Docker

You can run the service that you developed in the Quick Start Guide as a Docker container. The Ballerina language includes a [Ballerina_Docker_Extension](https://github.com/ballerinax/docker) that offers native support to run Ballerina programs on containers.

To run your service as a Docker container, add the corresponding Docker annotations to your service code. To add Docker support, add the following code to the .bal file of the service you created above.

```ballerina
import ballerina/http;
import ballerina/log;
import ballerina/docker;

http:Client grandOakHospital = new("http://localhost:9091/grandOak");
http:Client pineValleyHospital = new("http://localhost:9092/pineValley");

@docker:Config {
    push: true,
    registry: "index.docker.io/${DOCKER_USERNAME}",
    name: "healthcare",
    tag: "v2.0.0",
    username: "${DOCKER_USERNAME}",
    password: "${DOCKER_PASSWORD}"
}
@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcare on new http:Listener(9090) {
```

Now your code is ready to generate deployment artifacts. In this case it is a Docker image. Navigate to the directory of your porject and run the following command to build the module and generate the Docker artifacts.
  
```bash
$ ballerina build healthcare_service
```

You get the following output.

```bash
Compiling source
	wso2/healthcare_service:0.1.0

Creating balos
	target/balo/healthcare_service-2019r3-any-0.1.0.balo

Running tests
    wso2/healthcare_service:0.1.0
	No tests found


Generating executables
	target/bin/healthcare_service.jar

Generating docker artifacts...
	@docker 		 - complete 3/3 

	Run the following command to start a Docker container:
	docker run -d -p 9090:9090 index.docker.io/<username>/healthcare:v2.0.0
```

Use the following command to view the Docker images that are running.

```bash
$ docker images  

```

You see something similar to the following output.

```bash
REPOSITORY                                                TAG                     IMAGE ID            CREATED             SIZE
<username>/healthcare                                     v2.0.0                  c98de901fa4a        13 minutes ago      106MB
```
  
You can run a Docker container by copying and pasting the Docker `run` command that displays as output of the Ballerina `build` command.

```bash
$ docker run -d -p 9090:9090 index.docker.io/<username>/healthcare:v2.0.0

```

The following command allows you to view the active containers that are running. This allows you to test if your service is running.

```bash
$ docker ps  

```

This results in the following output.

```bash
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                    NAMES
37b3cc3ffd73        <username>/healthcare:v2.0.0          "/bin/sh -c 'java -j…"   6 seconds ago       Up 4 seconds        0.0.0.0:9090->9090/tcp   awesome_hoover
```

Invoke the service with a cURL command:

```bash
$ curl http://localhost:9090/healthcare/doctor/physician  
```
