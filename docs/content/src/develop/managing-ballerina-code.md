# Managing Ballerina Code

When you write large programs often you would want to organize your code into shareable units. 
In Ballerina, you can divide your program into such units, which are called Ballerina modules. 
Ballerina modules reside within a Ballerina project. You can have multiple modules within a 
Ballerina project. 

To create a project you can use the WSO2 Ballerina VS Code plugin or the Ballerina CLI tool.

## Creating a project

To create a new Ballerina project with Ballerina CLI tool use `ballerina new`:

```bash
$ ballerina new hello-world
```

Let's see what Ballerina CLI tool has generated for us.

```bash
$ cd hello-world
$ tree .
.
├── Ballerina.toml
└── src

1 directory, 1 file

```

Let's take a look at the `Ballerina.toml` file

```toml
[project]
org-name= "wso2"
version= "0.1.0"

[dependencies]

```

This is a manifest file. This file is used by the compiler to identify a Ballerina project directory. 
Please note that the `B` is capital in Ballerina.toml file.

We will get into more details about `Ballerina.toml` file as we progress through this guide.

## Ballerina Modules

Within the `src` directory of a Ballerina project, you can have multiple directories. Each directory 
will be treated as a Ballerina module.

A module is a directory that contains Ballerina source code files and is part of a namespace. Modules 
facilitate collaboration, sharing, and reuse. Modules can include functions, connectors, constants, 
annotations, services, and objects. To share a module among programs, projects, and users you need to 
push the module into a repository like Ballerina Central.

> **Tip**: Module names can contain alphanumeric characters including dots `.`. Dots in a module name 
> have no meaning other than the last segment after the final dot being used as a default alias within 
> your source code.

To create a Ballerina Module you can simply do either one of the following,

- create a directory within the src directory 
- use the WSO2 Ballerina Integrator VS Code plugin with predefined templates or
- use the Ballerina CLI tool

To create a Ballerina Module using the Ballerina CLI tool use `ballerina add` command. 

```bash
$ ballerina add hello-service -t service # ballerina add <module-name> -t <template-name>[:<version>]
```

> Note that you have to run this command within a Ballerina project directory. Here we are creating 
> a Ballerina module using a template called `service`. Optionally you can provide the template version.

Let's see what Ballerina CLI tool has generated with this command.

```bash
tree .
.
├── Ballerina.toml
└── src
    └── hello_service
        ├── hello_service.bal           # contains default hello service
        ├── Module.md                   # module level documentation
        ├── resources                   # resources for the module (available at runtime)
        └── tests                       # tests for this module (e.g. unit tests)
            ├── hello_service_test.bal  # test file for main
            └── resources               # resources for these tests

5 directories, 4 files
```

If you open up the `hello_service.bal` file you can see that the module was created with a `service`
template that responds to requests coming into `http://localhost:9090/hello/sayHello.

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

## Building the Project

To build the project we can use the `ballerina build` command:

```bash
$ ballerina build hello_service # ballerina build <module-name>
Compiling source
        wso2/hello_service:0.1.0

Creating balos
        target/balo/hello_service-2019r3-any-0.1.0.balo

Running tests
    wso2/hello_service:0.1.0
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
I'm the before suite service function!
Do your service Tests!
I'm the after suite service function!
        1 passing
        0 failing
        0 skipped

Generating executables
        target/bin/hello_service.jar
```

If you look at the code there are four phases in the build process. Namely,

- compiling the source code
- creating balos (Sharable representation of a module)
- Running the tests
- Generating executables

If you are writing a module that does not have a `main` or a `service` entry point, you wouldn't need to create the
executable since the module you created can only be used by another module. 

In that case, you can instruct the Ballerina CLI tool to ignore the executable creation phase by 
providing the `-c` argument.

```bash
$ ballerina build hello_service -c
``` 

## Ballerina Central: Public Module Repository

Once you have built your Ballerina project you can store your modules in a public directory called 
[Ballerina Central](#https://central.ballerina.io/). Users can share their module with others using Ballerina central

You can retrieve modules, and store modules in Ballerina Central using Ballerina CLI tool. 

### Retrieving Modules

To retrieve a module from Ballerina Central you can use the `ballerina pull` command.
```bash
$ ballerina pull wso2/gmail # ballerina pull <org-name>/<module-name>[:<version>]
```

> Note: If the version is not specified the latest version will be pulled.

### Storing Modules

To store a module in Ballerina Central you need proper permissions and an updated Ballerina.toml file

Before pushing the module to Ballerina Central you need to update the Ballerina.toml file. 

Here is an example toml file ready to be uploaded to Ballerina Central.

```toml
[project]
org-name= "wso2"
version= "0.10.1"
authors = ["WSO2"]
repository = "https://github.com/wso2-ballerina/module-gmail"
keywords = ["gmail","email"]
license = ["Apache-2.0"]

[dependencies]

```

To push a module to Ballerina Central you need a token for a valid account in Ballerina Central. This can be an
account that you created or an organizational account that is shared among multiple users. 

> To get your token, register on Ballerina Central and visit the user dashboard at 
> [https://central.ballerina.io/dashboard](https://central.ballerina.io/dashboard).

Once you get hold of the token for a particular account you can update your Ballerina `settings.toml` 
located at your `.ballerina` directory in home directory (`~/.ballerina/Settings.toml`)

```toml
[central]
accesstoken="<your_accesstoken>" 
```

> If you are connected to the internet via an HTTP proxy, add the following section to `Settings.toml` 
> and change accordingly.
>
> ```toml
> [proxy]
> host = "localhost"
> port = "3128"
> username = ""
> password = ""
> ```

Once `Settings.toml` and the `Ballerina.toml` are updated, you are ready to push your module into Ballerina Central.

Let's use the `ballerina push` command to store the module in Ballerina Central.

```bash
$ ballerina push gmail # ballerina push <module-name>
```

## Importing Modules

Your Ballerina source files can import modules:

```ballerina
import [<org-name>]/<module-name> [as <identifier>];
```

When you import a module, you can use its functions, annotations, and other objects in your code. You can also 
reference the objects with a qualified identifier, followed by a colon `:`. 

For example, `<identifier>:<module-object>`.

Identifiers are either derived or explicit. The default identifier is either the module name, or if the module name 
has dots `.` included, then the last word after the last dot. 

For example, `import ballerina/http;` will have `http:` as the derived identifier. 
The module `import wso2/net.http.exception` would have `exception:` as the default identifier.

You can have an explicit identifier by using the `as <identifier>` syntax.

```ballerina
import ballerina/http;

// The 'Service' object comes from the imported module.
service hello on new http:Listener(9090) {

    // The 'Request' object comes from the imported module.
    resource function sayHello (http:Caller caller, http:Request req) {
        ...
    }
}
```

Or you can override the default identifier:
```ballerina
import ballerina/http as network;

service hello on new network:Listener(9090) {

    // The 'Request' object comes from the imported module.
    resource function sayHello (network:Caller caller, network:Request req) {
        ...
    }
}
```

## Module dependencies

### Versioned Dependencies

If your source file or module is a part of a project, then you can explicitly manage version dependencies of 
imported modules within the project by defining it in `Ballerina.toml`:

```toml
[dependencies]
"wso2/http" = "3.0.1"
```

### Dependencies Without Versions

If an import version is not specified in `Ballerina.toml`, the compiler will use the `latest` module version 
from a repository, if one exists.

```ballerina
import wso2/http;

public function main() {
  http:Person x = http:getPerson();
}
```

### Path Dependencies

When you want to depend on a module that you have not uploaded to a remote repository you can use 
path dependencies in a `Ballerina.toml` file.

```toml
[dependencies]
"wso2/gmail" = { path = "path/to/gmail.balo" }
"wso2/gsheets4" = { path = "path/to/gsheets4.balo", version = "0.9.1"}
```

> Once you compile the dependent project, the relevant balo file is created within the `target/balo` directory
> of that project. You can give either the relative path or the absolute path to the balo file of the dependent 
> project from your project.

### Platform Dependencies

With jBallerina you can depend on Java libraries and interoperate with them. To do that and to make the 
compiler aware of the Java libraries we have to update the `Ballerina.toml` file.

```toml
[platform]
target = "java8"

  [[platform.libraries]]
  module = "jms"                                # Specifies which module is using this dependency
  path = "../utils/target/jms-utils-0.6.2.jar"  # Relative or absolute path to jar file
  artafactId = "jms-utils"                      # Jar artifact id
  version = "0.6.2"                             # Jar file version
  groupId = "org.wso2.ei"                       # Jar file group id

  [[platform.libraries]]
  module = "jms"
  path = "../utils/target/classes/lib/javax.jms-api-2.0.1.jar"
  artafactId = "javax.jms-api"
  version = "2.0.1"
  groupId = "javax.jms"
```

## Further Reading

You can read more about structuring your Ballerina code in the 
[How to Structure Ballerina Code](https://v1-0.ballerina.io/learn/how-to-structure-ballerina-code/) 
topic in the Ballerina documentation.
