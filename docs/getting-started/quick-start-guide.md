# Quick Start Guide

This section helps you to quickly set up and run Ballerina so that you can use it for various solutions. Here we 

## Install Ballerina

1. [Download](https://ballerina.io/downloads) Ballerina for your Operating System. 
1. Follow the instructions given in the [Ballerina Getting Started page](#https://ballerina.io/learn/getting-started/) to set it up. 

> **Note**: Throughout this documentation, `<ballerina_home>` refers to the directory in which you just installed Ballerina.

## Start a Project, Run a Service, and Invoke It

Create a new project by navigating to a directory of your choice and running the following command. 

```bash
$ ballerina new MyProject
```

You see a response confirming that your project is created. Navigate into the project directory you created and run the following command. This command enables you to create a module using a predefined template. In this case, we use the service template.

```bash
$ ballerina create MyProject -t service
```

This automatically creates a typical Hello World service for you inside an `src` directory. A Ballerina service represents a collection of network accessible entry points in Ballerina. A resource within a service represents one such entry point. The generated sample service exposes a network entry point on port 9090.

Navigate to the `src` directory and run the service using the `ballerina run` command.

```bash
$ ballerina run hello_service.bal
```

You get the following output.

```bash
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```

This means your service is up and running. You can invoke the service using an HTTP client. In this case, we use cURL.

```bash
$ curl http://localhost:9090/hello/sayHello
```

> **Tip**: If you do not have cURL installed, you can download it from [https://curl.haxx.se/download.html](https://curl.haxx.se/download.html).

You get the following response.

```
Hello Ballerina!
```

You just started Ballerina, created a project, started a service, invoked the service you created, and received a response.

## Set up the Editor

Let's try this on VS Code.

> **Tip:** You can use your [favorite editor to work on Ballerina code](#https://ballerina.io/learn/tools-ides/), however, we recommend you use VS Code as we have made some improvements to it for use in integration scenarios.

Open your service in VS Code. You can use the following command to do this on Linux or OSX. Replace '/<folder_path>/' with the actual folder path in which the Ballerina project was initialized.

1. Download and install [VS Code](#https://code.visualstudio.com/Download).

2. Execute the below commands based on your OS to open your service in VS Code. 

```bash
$ code /<folder_path>/hello_service.bal
```

On Windows, use the following.

```bash
$ code <folder_path>\hello_service.bal
```

> **Tip**: If you want to create new .bal files in addition to the Hello World service, you can open the initial project folder into editor using `code /<folder_path>` (on Windows it is `code <folder_path>`. You can also open VS Code and directly navigate to the directory or file.

You can view your service in VS Code.

```ballerina
// A system module containing protocol access constructs
// Module objects referenced with 'http:' in code
import ballerina/http;
import ballerina/io;

# A service is a network-accessible API
# Advertised on '/hello', port comes from listener endpoint
service hello on new http:Listener(9090) {

    # A resource is an invokable API method
    # Accessible at '/hello/sayHello
    # 'caller' is the client invoking this resource 

    # + caller - Server Connector
    # + request - Request
    resource function sayHello(http:Caller caller, http:Request request) {

        // Send a response back to caller
        // -> indicates a synchronous network-bound call
        error? result = caller->respond("Hello Ballerina!");
        if (result is error) {
            io:println("Error in responding", result);
        }
    }
}
```

You can find an extension for Ballerina in the VS Code marketplace. For instructions on installing and using it, see [The Visual Studio Code Extension](#https://ballerina.io/learn/tools-ides/vscode-plugin/).
