# Creating a Project

## Using modules

A module is a directory that contains Ballerina source code files and is part of a namespace. Modules facilitate collaboration, sharing, and reuse. Modules can include functions, connectors, constants, annotations, services, and objects. To share a module among programs, projects, and users you need to push the module into a repository.

> **Tip**: Module names can contain alphanumeric characters including dots `.`. Dots in a module name have no meaning other than the last segment after the final dot being used as a default alias within your source code.

### Storing modules in a public directory

You can store your modules in a public directory called [Ballerina Central](#https://central.ballerina.io/). 

> **Tip**: Before you push your module, you must enter your Ballerina Central access token in `Settings.toml` in your home repository (`<USER_HOME>/.ballerina/`). To get your token, register on Ballerina Central and visit the user dashboard at [https://central.ballerina.io/dashboard](https://central.ballerina.io/dashboard).

The following are the steps you follow when working with modules.

![alt text](../../assets/img/module-to-central.png)

1. Pull an existing module from Ballerina Central to your local directory using the `ballerina pull` command.

2. Make your changes to customize the module for your integration scenario and build the module using `ballerina build` command.

3. By building the module you automatically create a `.toml` file. From this file, point to any dependancy `.jar` files that you have for your integration scenario.

4. Push the module you built back to Ballerina Central using the `ballerina push` command.

Once the module is pushed back to Ballerina Central it can be pulled by anyone who needs it.

### Storing modules in a private directory

You can store your modules in a private directory that . The following are the steps you follow when working with modules.

![alt text](../../assets/img/module-to-directory.png)

1. Pull an existing module from Ballerina Central to your local directory using the `ballerina pull` command.

2. Make your changes to customize the module for your integration scenario and build the module using `ballerina build` command.

3. By building the module you automatically create a `.toml` file. From this file, point to any dependancy `.jar` files that you have for your integration scenario.

4. Push the module you built to a private directory or storage system that you have in place.

5. Only those who have access to the private directory can then use the module.

### Pushing a module

#### CLI command

Pushing a module uploads it to [Ballerina Central](https://central.ballerina.io/).

```
ballerina push <module-name>
```

#### Organizations

When you push a module to Ballerina Central, the runtime validates organizations for the user against the org-name defined in your module’s `Ballerina.toml` file. Therefore, when you have more than one organization in Ballerina Central, be sure to pick the organization name that you intend to push the module into and set that as the `org-name` in the `Ballerina.toml` file inside the project directory.

### Importing modules

Your Ballerina source files can import modules:

```ballerina
import [<org-name>]/<module-name> [as <identifier>];
```

When you import a module, you can use its functions, annotations, and other objects in your code. You can also reference the objects with a qualified identifier, followed by a colon `:`. For example, `<identifier>:<module-object>`.

Identifiers are either derived or explicit. The default identifier is either the module name, or if the module name has dots `.` included, then the last word after the last dot. For example, `import ballerina/http;` will have `http:` be the derived identifer. The module `import sam/net.http.exception` would have `exception:` as the default identifier.

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

### Module version dependency
If your source file or module is a part of a project, you can explicitly manage version dependencies of imported modules within the project by defining it in `Ballerina.toml`:

```toml
[dependencies."tyler/http"]
version = "3.0.1"
```

If an import version is not specified in `Ballerina.toml`, the compiler will use the `latest` module version from a repository, if one exists.

```ballerina
import tyler/http;

public function main() {
  http:Person x = http:getPerson();
}
```

### Compiled modules
A compiled module is the compiled representation of a single module of Ballerina code, which includes transitive dependencies into the compiled unit.

Modules can only be created, versioned, and pushed into a repository as part of a *project*.

### Running compiled modules
An entrypoint such as a `main()` or a `service` that is compiled as part of a named module is automatically linked into a `.balx`. You can run the compiled module `.balx`:

```bash
ballerina run module.balx
```


