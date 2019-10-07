# Re-introducing Ballerina Programming Language

Why does the Ballerina programming language need a re-introduction? You might be a total stranger to 
the Ballerina programming language, or you have tried it in the past and now you want to try out the latest 
jBallerina 1.0 release with WSO2 Ballerina Integrator. 

In either case, we are going to skim through the most important parts of the language that you need to know 
before you write Ballerina programs. If you want in-depth learning material you can always refer 
[the Ballerina language documentation](https://v1-0.ballerina.io/learn/)

## Table of Contents
- [Re-introducing Ballerina Programming Language](#re-introducing-ballerina-programming-language)
  - [Table of Contents](#table-of-contents)
  - [Introduction to Ballerina Platform](#introduction-to-ballerina-platform)
    - [Language Specification](#language-specification)
    - [Compiler and Runtime](#compiler-and-runtime)
    - [Standard Library](#standard-library)
      - [The Lang Library](#the-lang-library)
      - [Ballerina Platform Library](#ballerina-platform-library)
    - [Ballerina Central](#ballerina-central)
    - [Ballerina CLI Tool](#ballerina-cli-tool)
    - [LSP Implementation](#lsp-implementation)

## Introduction to Ballerina Platform

Overall Ballerina platform consists of following key components.

- [Re-introducing Ballerina Programming Language](#re-introducing-ballerina-programming-language)
  - [Table of Contents](#table-of-contents)
  - [Introduction to Ballerina Platform](#introduction-to-ballerina-platform)
    - [Language Specification](#language-specification)
    - [Compiler and Runtime](#compiler-and-runtime)
    - [Standard Library](#standard-library)
      - [The Lang Library](#the-lang-library)
      - [Ballerina Platform Library](#ballerina-platform-library)
    - [Ballerina Central](#ballerina-central)
    - [Ballerina CLI Tool](#ballerina-cli-tool)
    - [LSP Implementation](#lsp-implementation)

### Language Specification

The language specification is versioned and released independent of it implementations. Naming depends on 
the year the specification is released and the version released for the given year. Ballerina Integrator and
it's client Connectors are written based on [2019R3](https://v1-0.ballerina.io/spec/lang/v2019R3/) version 
of the language specification.

### Compiler and Runtime

Compiler implementations are versioned independently based on a particular language specification. jBallerina is one 
such implementation of the Ballerina language specification. jBallerina 1.0.0 is based on language specification 
[2019R3](https://v1-0.ballerina.io/spec/lang/v2019R3/). 

You can get this information by running the Ballerina version command

```bash
$ ballerina -v
Ballerina 1.0.0
Language specification 2019R3
```

### Standard Library

Standard library is a collection of Ballerina modules. All these modules are released under the reserved 
`ballerina` organization name.

#### The Lang Library
These subset of Ballerina modules versioned and released together with a particular version of the language 
specification. 

- ballerina/lang.int
- ballerina/lang.string
- ballerina/lang.array
- ballerina/lang.map
- ballerina/lang.future

#### Ballerina Platform Library

All the other modules in the standard library are versioned and released independent of 
the language specification.

Following are some example platform modules.

- ballerina/http
- ballerina/math
- ballerina/file
- ballerina/grpc

### Ballerina Central

[Ballerina Central](https://central.ballerina.io/) is a public module repository maintained by the Ballerina language
team. You can use this repository to share your Ballerina modules or to use publicly shared Ballerina modules. All the
WSO2 Ballerina Integrator related connectors are written as Ballerina modules and shared through Ballerina Central.

### Ballerina CLI Tool

Ballerina CLI tool is independent from all the other components mentioned earlier. You can think of this as a
CLI interface to interact with afore mentioned components of the Ballerina echosystem. 

For instance, you can use this tool to:

- create Ballerina projects and modules
- compile your Ballerina programs
- run unit tests
- generate API docs
- push modules to Ballerina central
- pull modules from Ballerina central
- Manage multiple Ballerina versions

### LSP Implementation

Ballerina language supports different IDEs like VS Code and IntelliJ Idea through its language server 
implementation.

