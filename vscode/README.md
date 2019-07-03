# Ballerina-Integrator VSCode Extension
### 1.0.0
Ballerina Integrator VSCode Extension is a tool that could be used alongside the Ballerina programming language to ease the creation of integration projects. The extension provides templates for integration use cases which could be used to create and start off new projects. It also contains code snippets for commonly used integration scenarios.

----
# User Guide
#### Requirements
  - Ballerina
  - Ballerina VSCode Extension
#### Quick Start
  - Install the Ballerina-Integrator VSCode Extension by WSO2. This is not released to the VSCode Marketplace yet, therefore this repository could be cloned and the .vsix file could be generated (using the 'vsce package' command) to install the extension. The extension could be installed by using the 'Extensions: Install from VSIX...' command in the VSCode Command Pallete. 
  - Go to the VSCode Command Palette and search for 'Ballerina: Generate Project from Ballerina Integrator Template' command to create a new project using an integration template.
  - Once the above command is selected, the 'Ballerina Integrator Templates' page will open, displaying the available templates along with a brief description. Select the required template style for the project. Make sure to have a workspace opened for the project beforehand.
  - A wizard page will be displayed to enter values for the placeholders used in the template. Default values specified in the template will be visible in the wizard.
  - The project will be created in the workspace opened once the “Create Project” button is clicked, after replacing the placeholder values.
  - To use  code snippets, you could type the first few letters of the snippet name and select it using the default VSCode autocomplete dropdown.
---
# Contributing Templates and Snippets
##### Templates
- Create a template with the appropriate folder structure and Ballerina code. Add placeholders in the required places using the following format.
    > Placeholder Format - ${placeholderName}
- Add the template to ./src/templates folder.
- Create a json element with details of the template and add it to ./src/templateDetails.json file in the format given below.
```json
{
       "id" : "T0001",
       "name" : "HelloWorld Service",
       "description" : "Contains a project template with a basic HelloWorld service.",
       "placeholders" : [
           {
               "id" : "P001",
               "label" : "Message",
               "name" : "message",
               "type" : "text",
               "value" : ["Hello World!"]
           },
           {
               "id" : "P002",
               "label" : "Listener Port",
               "name" : "listenerPort",
               "type" : "text",
               "value" : ["9090"]
           }
       ]
   }
```
Elements in the json given above are explained as follows.
* **id**: A unique identification for the template. The existing naming format could be used.
* **name**: An appropriate name for the template. This will be used as the label in WebViews.
* **description**: A brief explanation on what the template is about. 
* **placeholders**: Specify the details of placeholders used inside the template.
* **[placeholders] id**: A unique identification for the placeholder. The existing naming format could be used.
* **[placeholders] label**: A label for the placeholder. This will be used as the label in WebViews.
* **[placeholders] name**: A name for the placeholder. A CamelCase name is recommended.
* **[placeholders] type**: Type of the input expected for the placeholder value (e.g.: text, number, password and select).
* **[placeholders] value**: Default value for the placeholder. Could provide multiple values in the form of an array for 'select' option type.
##### Code Snippets
Take the code segment that is to be added as a snippet and convert into the VSCode snippet format. This [link](https://snippet-generator.app/?description=&tabtrigger=&snippet=&mode=vscode) could be used for the snippet generation. Go to the ./src/snippets/ballerina.json file and add the new code snippet.

-----
# Available Code Snippets
| Name | Description |
| ------ | ------ |
| HelloWorldService | A simple hello world service in ballerina language. |
