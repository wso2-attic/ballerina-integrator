# Ballerina Developer Workflow

This document provides design decisions taken to improve the workflow of a Ballerina integration project developer.

## Getting Started [Downloading the SDK]

An integration developer will come to WSO2 integration landing page in search of a solution to their intergration problem (via organic search, reference links etc) There will be an option to select the Ballerina based integration solution within the page.
This will navigate him to Ballerina integration related web page which consists of,

- A Getting started guide to setup the developer environment
- A set of integration use cases/examples with Ballerina
- Links to Ballerina project and learning material

## Project Templates support

Pre-defined integration scenarios, similar to templates provided in **WSO2 Integration Studio** are provided as Ballerina projct templates. This is to further reduce the boilerplate code written for widely used integration use cases.

The WSO2 Ballerina integration web page will contain examples related to the supported templates.

## Development Environment [VSCode user experience]

VSCode is the primary development tool for Ballerina integration development. A separate plugin called **Ballerina Integration Tools** should be downloaded to get the Ballerina integration related developer support.
This tool will support,

- Viewing the available integration templates
- Creating Ballerina integration related projects using templates
- Viewing available connectors in Ballerina central

### User Scenario:

Once a visitor navigates to the Ballerina integration page's getting started guide there should be instructions provided to download EI 7. Within EI7 there should be a script to setup the developer environment.

With this script, Ballerina should be installed in the developers environment. In addition, developer should get a prompt to download integration examples if they needs. Also, intructions should be given to setup the VS code based developer environment.
