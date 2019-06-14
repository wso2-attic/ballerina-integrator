# Using the Analytics Dashboard

Ballerina services can be monitored with the help of software such as Prometheus to provide useful statistics and metrics on the flow of requests to the endpints. 

In this example we will be making use of Prometheus and Grafana to track and monitor various endpoint related metrics

---
## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)

- A Text Editor or an IDE
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

- [Prometheus](https://prometheus.io/download/)
- [Grafana](https://grafana.com/grafana/download)
- [Healthcare Service](https://github.com/wso2/ballerina-integrator/tree/master/examples/guides/services/healthcare-service) running in the background

---
## Setting up Prometheus
[Prometheus](https://prometheus.io/) is used as the monitoring system, which pulls out the metrics collected from the Ballerina service '/metrics'. This section focuses on the quick installation of Prometheus with Docker, and configure it to collect metrics from Ballerina service with default configurations.

Below provided steps needs to be followed to configure Prometheus. There are many other ways to install the Prometheus and you can find possible options from [installation guide](https://prometheus.io/docs/prometheus/latest/installation/).

- Step 1 : Create a `prometheus.yml` file in `/tmp/` directory. 

- Step 2 : Add the following configuration content to `prometheus.yml` with the required IP

```
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['a.b.c.d:9797']
```

- Step 3 : Start Prometheus with the following command : `docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus`. We will be starting Promethus on port 19090 to avoid port conflicts. 

- Step 4 :  Go to http://localhost:19090/ and check whether you can see the Prometheus graph. Ballerina metrics should appear in Prometheus graph's metrics list when Ballerina service is started.


## Setting up Grafana
Let’s use [Grafana](https://grafana.com/) to visualize metrics in a dashboard. For this, we need to install Grafana, and configure Prometheus as a datasource. Follow the below provided steps and configure Grafana.

- Step 1 : Start Grafana as Docker container with below command.

`$ docker run -d --name=grafana -p 3000:3000 grafana/grafana`

Step 2: Go to http://localhost:3000/ to access the Grafana dashboard running on Docker.

Step 3: Login to the dashboard with default user, username: admin and password: admin

Step 4: Add Prometheus as datasource with Browser access configuration as provided below.

Step 5: Import the Grafana dashboard designed to visualize Ballerina metrics from https://grafana.com/dashboards/5841. This dashboard consists of service and client invocation level metrics in near real-time view.

![Alt text](examples/integration-tutorials/using-the-analytics-dashboard/resources/grafana-prometheus-datasource.png?raw=true "Grafana dashboard")

--- 
## How it works
The provided service makes calls to several endpoints in the Healthcare Service. These requests and responses are monitored by Prometheus and the metrics are displayed in Grafana

## Deploying the service
To deploy locally, navigate to using_the_analytics_dashboard, and execute the following command.

``` 
ballerina build using_the_analytics_dashboard.bal
``` 

This builds a Ballerina executable archive (.balx) of the services that you developed in the target folder. You can run them with the command:

```
ballerina run target/using_the_analytics_dashboard.balx
```


With the service running, send a GET request to `http://localhost:8080/analyticsService/analytics`. You can now view the metrics on Grafana.  



