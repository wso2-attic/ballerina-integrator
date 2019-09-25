# Observing a Service with Prometheus

There are mainly two systems involved in collecting and visualizing the metrics. [Prometheus](https://prometheus.io/) is used to collect the metrics from the Ballerina service and [Grafana](https://grafana.com/) can connect to Prometheus and visualize the metrics in the dashboard.

To understand how you can observe Ballerina services, let’s consider a service that converts JSON to XML.

![alt text](../../assets/img/prometheus-grafana.png)

As inferred by the above image, we will be getting metrics using Prometheus and displaying it using Grafana.

## Set up the project 

1. Open VS Code.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already. Find the extension for Ballerina in the VS Code marketplace if you do not have it. This extension is called `Ballerina`. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

2. Press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

Select the template to transform XML messages to JSON and your project will load.

Add the following configurations for metrics in the `ballerina.conf` file.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

```

## Set up Prometheus

**Step 1:** Create a `prometheus.yml` file in `/tmp/` directory.

**Step 2:** Add the following content to `/tmp/prometheus.yml`.

```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['a.b.c.d:9797']
```

Here the targets `'a.b.c.d:9797'` should contain the host and port of the `/metrics` service that's exposed from 
Ballerina for metrics collection. Add the IP of the host in which the Ballerina service is running as `a.b.c.d` and its
port (default `9797`). In this case, you can use your own IP address to try this.

> **Tip**: If you need more information refer [official documentation of Prometheus](https://prometheus.io/docs/introduction/first_steps/).

**Step 3:** Start the Prometheus server in a Docker container with below command.

```bash
$ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
```
    
**Step 4:** Go to <http://localhost:19090/> and check whether you can see the Prometheus graph.
Ballerina metrics should appear in Prometheus graph's metrics list when Ballerina service is started.

## Set up Grafana

Let’s use Grafana to visualize metrics in a dashboard. For this, we need to install Grafana, and configure
Prometheus as a datasource. Follow the below provided steps and configure Grafana.

**Step 1:** Start Grafana as Docker container with below command.

```bash
$ docker run -d --name=grafana -p 3000:3000 grafana/grafana
```
For more information refer [Grafana in Docker Hub](https://hub.docker.com/r/grafana/grafana/).

**Step 2:** Go to <http://localhost:3000/> to access the Grafana dashboard running on Docker.

**Step 3:** Log in to the dashboard with default user, username: `admin` and password: `admin`

**Step 4:** Add Prometheus as datasource with `Browser` access configuration as provided below. See [Grafana documentation regarding Prometheus](https://grafana.com/docs/features/datasources/prometheus/) for more information on how to do this.

![alt text](../../assets/img/grafana-prometheus-datasource.png)

- Use `Prometheus` as the **Name** of the datasource.
- In the **HTTP** section, enter `http://localhost:19090` as the **URL**.
- Choose `Browser` from the **Access** dropdown list.
- Click **Save & Test** to see if the connection works.

**Step 5:** Import the Grafana dashboard designed to visualize Ballerina metrics from [https://grafana.com/dashboards/5841](https://grafana.com/dashboards/5841). See [Grafana documentation regarding exporting and importing dashboards](https://grafana.com/docs/reference/export_import/) for more information on how to do this.
This dashboard consists of service and client invocation level metrics in near real-time view. 

## Visualizing metrics on Grafana

Ballerina HTTP Service Metrics Dashboard Panel will be as below.

![alt text](../../assets/img/prometheus-grafana-metrics.png)
