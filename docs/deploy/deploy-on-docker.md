# Deploying on Docker

Deploying your Ballerina code is easier than ever with the growth of containers and container platforms such as Kubernetes.

Deploying a Ballerina integration service is the process of creating assets that ready the program and service(s) for activation in another runtime, such as Docker Engine, Moby, Kubernetes, or Cloud Foundry. The Ballerina compiler is able to generate the necessary artifacts for different deployment annotations based on annotations that decorate the source code, which provide compiler instructions for artifact generation.

This topic provides instructions on how to deploy your project on [Docker](https://www.docker.com/). The project in this case, is the same one you used in the [Quick Start Guide](../../getting-started/quick-start-guide/).

> **Tip**: The `docker` command line tool needs to be installed and working. Try: `docker ps` to verify this. Go to the [install page](#https://get.docker.io/) if you need to install Docker.

## Set up the project 

1. Open VS Code.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already. Find the extension for Ballerina in the VS Code marketplace if you do not have it. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

2. Press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

Select the template to transform XML messages to JSON and your project will load.

## Deploying your service on Docker

You can run the service that you developed in the Quick Start Guide as a Docker container. The Ballerina language includes a [Ballerina_Docker_Extension](https://github.com/ballerinax/docker) that offers native support to run Ballerina programs on containers.

To run your service as a Docker container, add the corresponding Docker annotations to your service code. To add Docker support, add the following code to the .bal file of the service you created above.

```ballerina
import ballerina/docker;  
  
@docker:Config {
    push: true,
    registry: "index.docker.io/$env{DOCKER_USERNAME}",
    name: "sciencelab",
    tag: "v2.0.0",
    username: "$env{DOCKER_USERNAME}",
    password: "$env{DOCKER_PASSWORD}"
}
```

Now your code is ready to generate deployment artifacts. In this case it is a Docker image. Navigate to the directory of your porject and run the following command to build the module and generate the Docker artifacts.
  
```bash
$ ballerina build MyModule  

```

You get the following output.

```
Compiling source
	sam/MyModule:0.1.0

Creating balos
	target/balo/MyModule-2019r3-any-0.1.0.balo

Running tests
    sam/MyModule:0.1.0
	No tests found


Generating executables
	target/bin/MyModule.jar

Generating docker artifacts...
	@docker 		 - complete 2/2 

	Run the following command to start a Docker container:
	docker run -d -p 9191:9191 sciencelab:v2.0.0
	
```

Use the following command to view the Docker images that are running.

```bash
$ docker images  

```

You see something similar to the following output.

```
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
sciencelab             v2.0.0              d43ff0513901        34 minutes ago      109 MB

```
  
You can run a Docker container by copying and pasting the Docker `run` command that displays as output of the Ballerina `build` command.

```bash
$ docker run -d -p 9191:9191 sciencelab:v2.0.0

```

The following command allows you to view the active containers that are running. This allows you to test if your service is running.

```bash
$ docker ps  

```

This results in the following output.

```
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS              PORTS                    NAMES
8f1a10c89700        sciencelab:v2.0.0   "/bin/sh -c 'java ..."   44 minutes ago      Up 15 minutes       0.0.0.0:9191->9191/tcp   cranky_kowalevski
```

Invoke the service with a cURL command:

```bash 
$ curl -X POST -d @request.xml  http://localhost:9092/laboratory/user  -H "Content-Type: text/xml"  

```
