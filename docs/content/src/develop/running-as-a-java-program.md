# Running as a Java Program

Running a Ballerina program or service can be done using a Java command. This is useful since a .jar file is created as part of building the project and the program can be run using a `java -jar` command.

## Pre-requisites

To run Ballerina code as a Java program, you need to have Oracle JDK 1.8.* installed.

## Running the simple Java command

The following is an example of a `java -jar` command. This is used to run the project built in the [Quick Start Guide](../../get-started/quick-start-guide).

```java

$ java -jar target/bin/MyModule.jar --b7a.config.file=src/MyModule/resources/ballerina.conf

```

Note that in the above example, you first mention the location of the .jar file and follow this up by pointing to a configuration file where you are passing some parameters. Instead of pointing to the configuration file you could pass different parameters here as we will explore in this document.


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

$ java -jar program.jar —ballerina.config.secret=src/MyModule/resources/secret.txt

```

## Passing configurations as environment variables

If the values are not set in the config file, it is read from the environment variables. For example, if you set a=10 in the command line as an environment variable and if your program's configuration is reading config key a, it will read it as 10 even if the a value is set differently in the config file. So priority is given to the environment variable you set.

Consider the following example, which reads a Ballerina config value and prints it.

```ballerina
import ballerina/io;
import ballerina/config;

public function main() {
  string name = config:getAsString("hellouser");
  io:println("Hello, " + name + " !");
}
```

The config key is `hellouser`. To pass a value to this config from the CLI, we can run the following command.

Now you can pass the value of `hellouser` in the `java -jar` command itself as shown below:

```java

java -jar  main.jar --hellouser=Ballerina

```
Alternatively you can set it as an environment variable as follows.

```bash

$ export hellouser=Ballerina

```

Once you set the above, you can simply run the program using the `java -jar` command and it will provide the result you want.

```java

java -jar  main.jar

```

The following output is the result for either of the above two scenarios.

```bash

Hello, Ballerina !

```
