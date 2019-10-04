# Quick Start Guide

This section helps you to quickly set up and run Ballerina Integrator so that you can use it for various integration solutions.

## Install Ballerina

1. [Download](https://ballerina.io/downloads) Ballerina for your Operating System. 
1. Follow the instructions given in the [Ballerina Getting Started page](https://ballerina.io/learn/getting-started/) to set it up. 

> **Note**: Throughout this documentation, `<ballerina_home>` refers to the directory in which you just installed Ballerina.

## Set up the IDE

Let's try this on VS Code, which is the recommended IDE to use in Ballerina Integrator integration scenarios.

1. Open VS Code.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already.

2. Find the extension for Ballerina in the VS Code marketplace. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

Once you have installed the extension, press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

You can select one of the available templates or run it using the CLI as indicated in the following section.

## Create a Project, Add a Template, and Invoke the Service

Create a new project by navigating to a directory of your choice and running the following command. 

```bash
$ ballerina new healthcare-service
```

You see a response confirming that your project is created.

In this project, you will be creating a service that transforms an XML message to JSON.

![alt text](../../assets/img/xml-json.png)

First let's pull the module from Ballerina Central, which is a public directory that allows you to host templates and modules. In this case, we use the `xml_to_json_transformation` template.

```
$ ballerina pull wso2/healthcare_service
```

Navigate into the project directory you created and run the following command. This command enables you to create a module using the predefined template you pulled.

```bash
$ ballerina add -t wso2/healthcare_service doctors
```

This automatically creates an XML to JSON transformation service for you inside an `src` directory. A Ballerina service represents a collection of network accessible entry points in Ballerina. A resource within a service represents one such entry point. The generated sample service exposes a network entry point on port 9090.

Build the service using the `ballerina build` command.

```bash
$ ballerina build doctors
```

You get the following output.

```bash
Compiling source
	wso2/doctors:0.1.0

Creating balos
	target/balo/doctors-2019r3-any-0.1.0.balo

Running tests
    wso2/doctors:0.1.0
	No tests found


Generating executables
	target/bin/doctors.jar
```

Run the following Java command to run the executable .jar file that is created once you build your module.

```bash
$ java -jar target/bin/doctors.jar
```

Your service is now up and running. You can invoke the service using an HTTP client. In this case, we use cURL.

> **Tip**: If you do not have cURL installed, you can download it from [https://curl.haxx.se/download.html](https://curl.haxx.se/download.html).

```bash
$ curl http://localhost:9090/healthcare/doctor/physician
```

You get the following response.

```json
[
   {
      "name":"Shane Martin",
      "time":"07:30 AM",
      "hospital":"Grand Oak"
   },
   {
      "name":"Geln Ivan",
      "time":"08:30 AM",
      "hospital":"Grand Oak"
   },
   {
      "name":"Geln Ivan",
      "time":"05:30 PM",
      "hospital":"pineValley"
   },
   {
      "name":"Daniel Lewis",
      "time":"05:30 PM",
      "hospital":"pineValley"
   }
]
```

You just started Ballerina, created a project, started a service, invoked the service you created, and received a response.

To have a look at the code, navigate to the `hospital_service.bal` file found inside your module.

```
import ballerina/http;
import ballerina/log;

http:Client grandOakHospital = new("http://localhost:9091/grandOak");
http:Client pineValleyHospital = new("http://localhost:9092/pineValley");

@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcare on new http:Listener(9090) {

    @http:ResourceConfig {
        path: "/doctor/{doctorType}"
    }
    resource function getDoctors(http:Caller caller, http:Request request, string doctorType) returns error? {
        json grandOakDoctors = {};
        json pineValleyDoctors = {};
        var grandOakResponse = grandOakHospital->get("/doctors/" + doctorType);
        var pineValleyResponse = pineValleyHospital->post("/doctors", {doctorType: doctorType});
        // Extract doctors array from grand oak hospital response
        if (grandOakResponse is http:Response) {
            json result = check grandOakResponse.getJsonPayload();
            grandOakDoctors = check result.doctors.doctor;
        } else {
            handleError(caller, <@untained> grandOakResponse.reason());
        }
        // Extract doctors array from pine valley hospital response
        if (pineValleyResponse is http:Response) {
            json result = check pineValleyResponse.getJsonPayload();
            pineValleyDoctors = check result.doctors.doctor;
        } else {
            handleError(caller, <@untained> pineValleyResponse.reason());
        }
        // Aggregate grand oak hospital's doctors with pine valley hospital's doctors
        if (grandOakDoctors is json[] && pineValleyDoctors is json[]) {
            foreach var item in pineValleyDoctors {
                grandOakDoctors.push(item);
            }
        }
        // Respond back to the caller with aggregated json response
        http:Response response = new();
        response.setJsonPayload(<@untained> grandOakDoctors);
        var result = caller->respond(response);

        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}

function handleError(http:Caller caller, string errorMsg) {
    http:Response response = new;

    json responsePayload = {
        "error": {
            "message": errorMsg
        }
    };
    response.setJsonPayload(responsePayload, "application/json");
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error sending response", err = result);
    }
}
```
