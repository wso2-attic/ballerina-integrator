# Quick Start Guide

Let's get started with WSO2 Ballerina Integrator by running a simple use case in your local environment. This is a simple service orchestration scenario. The scenario is about a basic health care system where Ballerina Integrator is used to integrate two backend hospital services to provide information to the client.

Most healthcare centers have a system that is used to make doctor appointments. To check the availability of the doctors for a particular time, users need to visit the hospitals or use each and every online system that is dedicated for a particular healthcare center. Here we are making it easier for patients by orchestrating those isolated systems for each healthcare provider and exposing a single interface to the users.

![alt text](../../assets/img/BI-quick-start-guide.png)

In the above scenario, the following takes place:

1. The client makes a call to the Healthcare service created using Ballerina Integrator.

2. The Healthcare service calls the Pine Valley Hospital backend service and gets the queried information.

3. The Healthcare service calls the Grand Oak Hospital backend service and gets the queried information.

4. The response is returned to the client with the required information.

Both Grand Oak Hospital and Pine Valley Hospital have services exposed over HTTP protocol.

Pine Valley Hospital service accepts a POST request in following service endpoint URL.

```bash
http://<HOST_NAME>:<PORT>/pineValley/doctors
```

The expected payload should be in the following JSON format.

```json
{
    "doctorType": "<DOCTOR_TYPE>"
}
```

Grand Oak Hospital service accepts a GET request in following service endpoint URL.

```bash
http://<HOST_NAME>:<PORT>/grandOak/doctors/<DOCTOR_TYPE>
```

Let’s implement a simple service that can be used to query for availability of doctors for a particular category from all the available healthcare centers.

## Before you begin

1. [Download Ballerina Integrator](https://www.wso2.com/integration/ballerina-integrator) for your Operating System. 

2. Download the sample files from [here](https://github.com/wso2/docs-ei/tree/7.0.0/en/micro-integrator/docs/assets/attach/quick-start-guide). From this point onwards, let's refer to this folder as `<BI_QSG_HOME>`.

3. Download [curl](https://curl.haxx.se/) or a similar tool that can call an endpoint.

4. Start up VS Code, which is the recommended IDE to use in Ballerina Integrator integration scenarios.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already.

5. Find the extension for Ballerina in the VS Code marketplace. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

Once you have installed the extension, press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

## Create a Project, Add a Template, and Invoke the Service

Create a new project by navigating to a directory of your choice and running the following command. 

```bash
$ ballerina new quick-start-guide
```

You see a response confirming that your project is created.

Let's use a predefined module from Ballerina Central, which is a public directory that allows you to host templates and modules. A module is a directory that contains Ballerina source code files, while a template is a predefined code that solves a particular integration scenario. In this case, we use the `healthcare_service` module. Navigate into the project directory you created and run the following command.

```
$ ballerina pull wso2/healthcare_service
```

Now navigate into the above module directory you created. The following command enables you to apply a predefined template you pulled.

```bash
$ ballerina add -t wso2/healthcare_service healthcare_service
```

This automatically creates a healthcare service for you inside an `src` directory. A Ballerina service represents a collection of network accessible entry points in Ballerina. A resource within a service represents one such entry point. The generated sample service exposes a network entry point on port 9090.

Build the service using the `ballerina build` command.

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
```

Run the following Java command to run the executable .jar file that is created once you build your module.

```bash
$ java -jar target/bin/healthcare_service.jar
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

You just started Ballerina Integrator, created a project, started a service, invoked the service you created, and received a response.

To have a look at the code, navigate to the `hospital_service.bal` file found inside your module.
<details>
    <summary>Ballerina code</summary>

```ballerina
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
</details>

## What's Next

- Try out the tutorials available in the [Learn section of our documentation](../../learn/use-cases/).
- You can easily deploy the projects you create by following our documentation on [Docker](../../learn/deploy-on-docker/) and [Kubernetes](../../learn/deploy-on-kubernetes/).
