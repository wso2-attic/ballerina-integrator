# WSO2 Ballerina Integrator
## 1.0.0

Ballerina Integrator VSCode Extension is a tool that could be used alongside the Ballerina programming language to ease the creation of integration projects. This extension provides templates for integration use cases that could be used to create and start new projects. It also contains code snippets for commonly used integration scenarios.

## User Guide

### Requirements
  - Visual Studio Code
  - Ballerina (v1.0.0)
  - Ballerina VSCode Extension (v1.0.0)

### Installation
* **Using the VSCode Marketplace**

    Install the `Ballerina Integrator` VSCode Extension by WSO2.
*Please note that this extension has not been released to the VSCode Marketplace yet.*

* **Using a .vsix File**
   * Prerequisites:
     - Node.js / NPM
     - Yeoman and  VSCode Extension Generator
        ```
        npm install -g yo generator-code
        ```
     - Visual Studio Code Extension Manager
        ```
        npm install -g vsce
        ```
   - Clone [this](https://github.com/wso2/ballerina-integrator) repository and open the `vscode/extension` folder in Visual Studio Code.
   - Load the required node modules using the following command.
        ```
        npm install
        ```
   - Generate a .vsix file using the following command.
        ```
        vsce package
        ```
   - Install the extension using `Extensions: Install from VSIX...` command in the VSCode Command Pallete and by selecting the .vsix file created in the previous step.

### Quick Start
- **Step 1:** Install the WSO2 Ballerina Integrator extension for Visual Studio Code.
- **Step 2:** Use the command `Ballerina Integrator: Home` through the command palette to start creating projects and modules using multiple different templates provided by WSO2.

### Features
- Create New Project
- Create New Module from Template
- Search for Templates

## Contributing Templates
Create a Ballerina project with a template module for an integration scenarios.
Add the following property in the project's Ballerina.toml file.
```
templates= ["template_module_name"]
```
Build the template using the following command.
```
ballerina build <module_name>
```
Push the template module to Ballerina Central through a registered organization using the following command at the project's base folder. More details can be found [here](https://v1-0.ballerina.io/learn/).
```
ballerina push <organization_name>/<module_name>
```
Add the project to [templates directory](https://github.com/wso2/ballerina-integrator/tree/master/templates) in the Ballerina Integrator GitHub repository for maintenance purposes.
