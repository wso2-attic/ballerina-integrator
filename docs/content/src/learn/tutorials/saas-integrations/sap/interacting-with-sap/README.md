# Interacting with SAP

## About

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the support of connectors. In this guide, we are mainly focusing on interacting with a SAP R/3 backend using BAPI requests and IDoc messages.

SAP is an industry leading enterprise software solution that is widely used among product and process oriented enterprises for finance, operations, HR and many other aspects of a business. SAP ERP solutions provide reliable and efficient platforms to build and integrate enterprise or business-wide data and information systems with ease. 

The Ballerina SAP Connector provides an integration layer that allows interacting with SAP R/3 based solutions. Ballerina SAP Client acts as a SAP producer while the Ballerina SAP Listener acts as a SAP consumer. The connector has full IDoc and experimental BAPI support. It uses the SAP JCO library as the underlying framework to communicate with the SAP system.

You can find other integration modules from [wso2-ballerina](https://github.com/wso2-ballerina) GitHub organization.

Following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you'll build

This application demonstrates a scenario where a client application interacts with a SAP endpoint using BAPI and IDoc. The BAPI request would provide the response from the backend and if an error happens during the message flow, it would be returned to the user. A successful IDoc message send would return the associated transaction id.

## Prerequisites

- [Java](https://www.oracle.com/technetwork/java/index.html)
- Ballerina Integrator
- A Text Editor or an IDE
    > **Tip**: For a better development experience, install the `Ballerina Integrator` extension in [VSCode](https://code.visualstudio.com/).
- SAP R/3 instance with `sapidoc3.jar`, `sapjco3.jar` and the native SAP JCo library.

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the `Testing` section by skipping the `Implementation` section.

1. Create a new project.

```bash
$ ballerina new interacting-with-sap
```

2. Navigate to the project directory and add a module using the following command.

```bash
ballerina add sap_producer
```
3. Copy the native SAP JCo library into the system path. You need to select the system path applicable to your operating system as described below.
> **Linux 32-bit**: Copy the Linux native SAP jcolibrary `libsapjco3.so` to `<JDK_HOME>/jre/lib/i386/server`.

> **Linux 64-bit**: Copy the Linux native SAP jcolibrary `libsapjco3.so` to `<JDK_HOME>/jre/lib/amd64`.

> **Windows**: Copy the Windows native SAP jcolibrary `sapjco3.dll` to `<WINDOWS_HOME>/system32`.

4. Create a `lib` directory in the project root and copy the `sapidoc3.jar` and `sapjco3.jar` .jar files into it. Point these .jar files in the `Ballerina.toml` file as follows.
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
5. Add a `ballerina.conf` file and create .bal files with meaningful names as shown in the project structure given below.
```
interacting-with-sap
├── Ballerina.toml
├── ballerina.conf
└── src
    └── sap_producer
        ├── Module.md
        ├── sap_producer.bal
        ├── resources
        └── tests
            ├── resources
            └── sap_producer_test.bal
```

6. Add SAP endpoint properties in the `ballerina.conf` file. Given below is a sample with mandatory properties.
```
DESTINATION_NAME = "CPT"
SAP_CLIENT = "800"
USERNAME = "wso2_user"
PASSWORD = "wso2_pass"
ASHOST = "/H/217.116.29.154/S/3299/H/10.100.5.120/S/3200"
SYSNR = "01"
LANGUAGE = "en"
```

7. A SAP client can be configured as follows. Ballerina Integrator VS Code plugin contains a snippet for the same, which could be loaded using the autocomplete feature for `client/sap` keyword.
```
sap:ProducerConfig producerConfigs = {
    destinationName: config:getAsString("DESTINATION_NAME"),
    sapclient: config:getAsString("SAP_CLIENT"),
    username: config:getAsString("USERNAME"),
    password: config:getAsString("PASSWORD"),
    ashost: config:getAsString("ASHOST"),
    sysnr: config:getAsString("SYSNR"),
    language: config:getAsString("LANGUAGE")
};

sap:Producer sapProducer = new (producerConfigs);
```

8. Functions `sendBapi()` and `sendIdoc()` can be used to send the BAPI requests and IDoc messages respectively.

## Testing

Let’s build the module. Navigate to the project directory and execute the following command.

```bash
ballerina build sap_producer
```

The build command creates an executable .jar file. Now run the .jar file created in the above step. Path to the `ballerina.conf` could be provided using the `--b7a.config.file` option.

```bash
java -jar target/bin/sap_producer.jar --b7a.config.file=path/to/ballerina.conf/file
```

If the requests are successful, you will get a BAPI response for the BAPI request and a transaction id for the IDoc message.

### Writing unit tests

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`. When writing test functions the convention given below should be followed.

Test functions should be annotated with `@test:Config {}`. See the example below.
```ballerina
@test:Config {}
function testIdocSend() {

}
```

This guide contains unit tests for sending BAPI and IDoc in the `sap_producer_test.bal`.

To run the unit tests, navigate to the project directory and run the following command.
```
ballerina test
```
> **Note:** The `--b7a.config.file=path/to/ballerina.conf/file` option is required if it is needed to read configurations from a Ballerina configuration file.
