# Introduction

WSO2 Enterprise Integrator (EI) 7.0 includes a Ballerina Integrator, which is a powerful code-based approach to integration. 

For developers, the Ballerina-based integration component marks a new phase of integration technology - a powerful, simple-to-learn, code-driven approach to programming integrations. It includes first-class cloud-native functions as well as a graphical sequence diagram tool. Since it is a programming language, integration developers can apply agile methodologies, truly bringing a new degree of speed and agility to integration projects. 

The following image is an illustration of what Ballerina Integrator consists of and the various components that work together to solve an integration problem.

![Ballerina Interator components](../../assets/img/ballerina-integrator-architecture.svg)

<table>
  <tr>
    <td><b>Ballerina Core</b></td>
    <td>The underlying core of the Ballerina Integrator is the [Ballerina language](http://ballerina.io/), which allows you to build projects and modules with smaller functionality and natively deploy these as microservices in Docker and Kubernetes.</td>
  </tr>
  <tr>
    <td>[Ballerina standard library](https://v1-0.ballerina.io/learn/api-docs/ballerina/?101) provides a rich set of in-built modules that help you build your integrations to support a variety of protocols, servers, and extensions.</td>
  </tr>
  <tr>
    <td><b>Connectors</b></td>
    <td>Integration connectors and Ballerina connectors offer extensibility and flexibility for integration and are used to connect to a variety of on-premise applications and services.</td>
  </tr>
  <tr>
    <td><b>Analytics</b></td>
    <td>Ballerina Integrator has in-built analytics that can be used to visualize metrics, analyze logs, and do distributed tracing.</td>
  </tr>
  <tr>
    <td><b>Templates</b></td>
    <td>Templates are used to quickly load up sample code that can be used for an integration scenario. This is designed to provide developers with a base to work with and customize the scenario to match their specific problem.</td>
  </tr>
  <tr>
    <td><b>Tooling</b></td>
    <td>Tooling is done via VS Code and the developer's experience is further enhanced by a custom built plug-in for Ballerina, which enables you to easily bring up and use templates to do integration.</td>
  </tr>
</table>
