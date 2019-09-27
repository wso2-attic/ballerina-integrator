# Running as Java Program

Running a Ballerina program or service can be done using a Java command. This is necessary since a .jar file is created as part of building the project.

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

## Securing configurations

Ballerina provides an API to access configuration values from different sources. For more information, see [Config Ballerina by Example](https://ballerina.io/learn/by-example/config-api.html).

Configuration values containing passwords or secrets should be encrypted. The Ballerina Config API will decrypt such configuration values when being accessed.

Use the following command to encrypt a configuration value:

```cmd
$ ballerina encrypt
```

The encrypt command will prompt for the plain-text value to be encrypted and an encryption secret.

```cmd
$ ballerina encrypt
Enter value:

Enter secret:

Re-enter secret to verify:

Add the following to the runtime config:
@encrypted:{pIQrB9YfCQK1eIWH5d6UaZXA3zr+60JxSBcpa2PY7a8=}

Or add to the runtime command line:
-e<param>=@encrypted:{pIQrB9YfCQK1eIWH5d6UaZXA3zr+60JxSBcpa2PY7a8=}
```

Ballerina uses AES, CBC mode with PKCS#5 padding for encryption. The generated encrypted value should be used in place of the plain-text configuration value.

For example, contents of a configuration file that includes a secret value should look as follows:

```
api.secret="@encrypted:{pIQrB9YfCQK1eIWH5d6UaZXA3zr+60JxSBcpa2PY7a8=}"
api.provider="not-a-security-sensitive-value"
```

When running a Ballerina program that uses encrypted configuration values, it is required to provide the secret used during the encryption process to perform the decryption.

A file named `secret.txt` is used for this purpose. If such file exists, the decryption secret is read from the file and immediately removed from the file to make sure secret cannot be accessed afterwards.

The file based approach is useful in automated deployments. The file containing the decryption secret can be deployed along with the Ballerina program. The name and the path of the secret file can be configured using the `ballerina.config.secret` runtime parameter:

```java

$ java -jar program.jar —ballerina.config.secret=path/to/conf/file/custom-config-file-name.conf

```
