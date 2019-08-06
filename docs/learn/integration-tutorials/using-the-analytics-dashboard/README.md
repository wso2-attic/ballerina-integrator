# Using the Analytics Dashboard

Ballerina services can be monitored with the help of tools such as Prometheus, which collect useful statistics and metrics about the request flow to the endpoints in a service.

In this tutorial, we will be making use of Prometheus and Grafana to track and monitor various endpoint related metrics.

#### What you will build

In the previous tutorials, we used the backend service of Health Care System to complete various use cases. In this tutorial, we will invoke different endpoints in the Health Care System using a set of functions, and collect analytic data about the backend using Prometheus. Prometheus is a monitoring tool which enables monitoring a given endpoint and collect data and Grafana is a tool which enables visualizing the metrics collected by Prometheus on a dashboard.

We will write a set of functions to invoke the Health Care Service backend, so that several requests will be invoked when running the service. Then, we can use Prometheus to monitor this service, collect the metrics related to the request flow, and view the metrics using Grafana. Ballerina offers in-built support for monitoring Ballerina code using Prometheus as mentioned in this [Ballerina guide](https://ballerina.io/learn/how-to-observe-ballerina-code/).

#### Prerequisites

- Download and install the [Ballerina Distribution](https://ballerina.io/learn/getting-started/) relevant to your OS.
- A Text Editor or an IDE
  > **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- [cURL](https://curl.haxx.se) or any other REST client
- Download the backend for Health Care System from [here](#)
- Download [Prometheus](https://prometheus.io/download/) for your OS
- Download and install [Grafana](https://grafana.com/grafana/download)

### Let's Get Started!

This tutorial includes the following sections.

- [Using the Analytics Dashboard](#Using-the-Analytics-Dashboard)
      - [What you will build](#What-you-will-build)
      - [Prerequisites](#Prerequisites)
    - [Let's Get Started!](#Lets-Get-Started)
    - [Implementation](#Implementation)
      - [Writing functions to invoke the Health Care System](#Writing-functions-to-invoke-the-Health-Care-System)
      - [Setting up Prometheus](#Setting-up-Prometheus)
      - [Setting up Grafana](#Setting-up-Grafana)
    - [Running the Implementation and viewing analytics](#Running-the-Implementation-and-viewing-analytics)

### Implementation

#### Writing functions to invoke the Health Care System

We will write a set of simple functions as below, each of which will invoke an endpoint in the Health Care backend. The following function will query for a list of doctors registered for a given specialization.

<!-- INCLUDE_CODE_SEGMENT: { file: guide/health_care_service.bal, segment: segment_1 } -->

We will then invoke these functions using a Ballerina service.

#### Setting up Prometheus

[Prometheus](https://prometheus.io/) is a monitoring system, which can pull metric data from an endpoint that is exposed from a system. Ballerina has in-built support for Prometheus, it exposes metric data on the predefined endpoint **/metrics** on port **9797**. In this section, we will focus on the installation of Prometheus and configuring it to collect metrics from Ballerina service with default configurations.

- Download and install [Prometheus](https://prometheus.io/download/) for your OS.

- Navigate to where Prometheus is installed in your machine, open the Prometheus configuration file **prometheus.yml**, and add the following configuration to add the Ballerina metric endpoint to Prometheus.

```
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'ballerina_metrics'
    static_configs:
      - targets: ['localhost:9797']
```

- Start Prometheus with the following command

```bash
$ ./prometheus
```

Prometheus will start on its default port 9090. We will modify the port to **19090** using the command line flag as below:

```bash
$ ./prometheus --web.listen-address ':19090'
```

- Now go to http://localhost:19090/ and check whether you can see the Prometheus browser. You can view the targets listened to by Prometheus, by viewing _Status > Targets_ page. You will see the _ballerina_metrics_ target as _UP_ when the Ballerina service is started.

#### Setting up Grafana

[Grafana](https://grafana.com/) is a tool that visualizes metric data on a dashboard. In this section, we will install and configure Prometheus as a datasource.

- Download and install [Grafana](https://grafana.com/docs/installation/debian/) and start Grafana as mentioned in the documentation.

- Go to http://localhost:3000/ to access the Grafana dashboard.

- Login to the dashboard with default user, username: admin and password: admin

- [Add Prometheus as a datasource](https://grafana.com/docs/guides/getting_started/#how-to-add-a-data-source) with Browser access configuration as displayed below.

![Alt text](examples/integration-tutorials/using-the-analytics-dashboard/resources/grafana-prometheus-datasource.png?raw=true "Grafana dashboard")

- Import the Grafana dashboard designed to visualize Ballerina metrics from https://grafana.com/dashboards/5841. This dashboard consists of service and client invocation level metrics in near real-time view.

### Running the Implementation and viewing analytics

The provided service makes calls to several endpoints in the Healthcare Service. These requests and responses are monitored by Prometheus and the metrics are displayed in Grafana.

- Start the HealthCareService backend.

- Start the Ballerina service with the **--observe** flag to enable publishing metrics from Ballerina to Prometheus.

```bash
$ ballerina run --observe health_care_service.bal
```

You will see that the metric publication has started as below:

```bash
ballerina: started publishing tracers to Jaeger on localhost:5775
Initiating service(s) in '/Library/Ballerina/ballerina-0.991.0/lib/balx/prometheus/reporter.balx'
[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9797
ballerina: started Prometheus HTTP endpoint 0.0.0.0:9797
```

- Start the configured Prometheus server, and check the active target _ballerina_metrics_ in _Status > Targets_ page.

- Start Grafana and view the statistics in the imported dashboard.
