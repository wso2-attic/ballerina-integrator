# Interacting with SAP

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on interacting with a SAP R/3 backend using BAPI requests and IDoc messages.

SAP is an industry leading enterprise software solution that is widely used among product and process oriented enterprises for finance, operations, HR and many other aspects of a business. SAP ERP solutions provide reliable and efficient platforms to build and integrate enterprise or business-wide data and information systems with ease. 

The Ballerina SAP Connector provides an integration layer that allows interacting with SAP R/3 based solutions. Ballerina SAP Client acts as a SAP producer while the Ballerina SAP Listener acts as a SAP consumer. The connector has full IDoc and experimental BAPI support. It uses the SAP JCO library as the underlying framework to communicate with the SAP system.

You can find other integration modules from [wso2-ballerina](https://github.com/wso2-ballerina) GitHub organization.

## What you'll build

This application demonstrates a scenario where a client application interacts with a SAP endpoint using BAPI and IDoc. The BAPI request would provide the response from the backend and if an error happens during the message flow, it would be returned to the user. A successful IDoc message send would return the associated transaction id.

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->
- SAP R/3 instance with `sapidoc3.jar`, `sapjco3.jar` and the native SAP JCo library.

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping the `Implementation` section.

#### 1. Creating the project structure

- Create a new project.

```bash
$ ballerina new interacting-with-sap
```

- Navigate to the project directory and add a module using the following command.

```bash
ballerina add sap_producer
```

- Project structure is created as indicated below.

```
interacting-with-sap
├── Ballerina.toml
└── src
    └── sap_producer
        ├── Module.md
        ├── sap_producer.bal
        ├── resources
        └── tests
            └── resources
```

#### 2. Copy the native SAP JCo library into the system path
You need to select the system path applicable to your operating system as described below.
> **Linux 32-bit**: Copy the Linux native SAP jcolibrary `libsapjco3.so` to `<JDK_HOME>/jre/lib/i386/server`.

> **Linux 64-bit**: Copy the Linux native SAP jcolibrary `libsapjco3.so` to `<JDK_HOME>/jre/lib/amd64`.

> **Windows**: Copy the Windows native SAP jcolibrary `sapjco3.dll` to `<WINDOWS_HOME>/system32`.

#### 3. Add `sapidoc3.jar` and `sapjco3.jar` files

Create a `lib` directory in the project root and copy the `sapidoc3.jar` and `sapjco3.jar` .jar files into it. 
Point these .jar files in the `Ballerina.toml` file as follows.
```
[platform]
target = "java8"

    [[platform.libraries]]
    module = "sapjco"
    path = "lib/sapjco3.jar"

    [[platform.libraries]]
    module = "sapidoc"
    path = "lib/sapidoc3.jar"
```

#### 4. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure.
Then add SAP endpoint properties in the `ballerina.conf` file. Given below is a sample with mandatory properties.

```
DESTINATION_NAME = "CPT"
SAP_CLIENT = "800"
USERNAME = "wso2_user"
PASSWORD = "wso2_pass"
ASHOST = "/H/217.116.29.154/S/3299/H/10.100.5.120/S/3200"
SYSNR = "01"
LANGUAGE = "en"
```

#### 5. Write the integration

**sap_producer.bal**
<!-- INCLUDE_CODE: src/sap_producer/sap_producer.bal -->

Functions `sendBapi()` and `sendIdoc()` can be used to send the BAPI requests and IDoc messages respectively.

## Testing

Let’s build the module. Navigate to the project directory and execute the following command.

```bash
ballerina build sap_producer
```

The build command creates an executable .jar file. Now run the .jar file created in the above step. 

```bash
java -jar target/bin/sap_producer.jar
```

If the requests are successful, you will get a BAPI response for the BAPI request and a transaction id for the IDoc message.
