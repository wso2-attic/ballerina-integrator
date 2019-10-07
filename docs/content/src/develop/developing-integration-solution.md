# Developing Integration Solutions

The contents on this page will walk you through the topics related to developing integration micro services for the WSO2 Ballerina Integrator.

## Development workflow

Integration developers will follow the workflow illustrated by the following diagram.

![developer workflow](../../assets/img/ballerina-integrator-developer-workflow.svg)

<table>
	<tr>
		<td><b>Step 1: Set up Ballerina Integrator</b></td>
		<td>
			To start developing your integration solutions, you need to first set up Ballerina Integrator:
			<ul>
				<li> <a href="https://wso2.com/integration/">Install Ballerina Integrator</a> from the installer, which you will use to build and test your integration.</li>
				<li><a href="https://www.docker.com/">Install Docker</a> if you want to test your solution in a containerized environment.</li>
				<li><a href="https://curl.haxx.se/">Install CURL</a> to test the integration solution by triggering the integration flow.</li>
			</ul>
		</td>
	</tr>
	<tr>
		<td><b>Step 2: Develop atomic and micro services</b></td>
		<td>
			To implement atomic and micro services, there are a number of Ballerina connectors and Integration connectors. Also, you can start with integration templates available in VS Code. Use the following resources:
			<ul>
				<li>
					<a href="../../learn/use-cases">Tutorials</a> will walk you through the process of developing the most common integration use cases.
				</li>
				<li>
					<a href="../../learn/examples">Examples</a> will provide a quick demo that will help you understand the Ballerina language for implementing specific functions.
				</li>
			</ul>
		</td>
	</tr>
	<tr>
		<td><b>Step 3: Build and run the service</b></td>
		<td>
		    Docker and Kubernetes supports comes out of the box with the Ballerina language. You can easily build micro service ready to deploy as a container.
			<ul>
				<li><a href="../../develop/deploy-on-docker">Deploy your services on Docker</a></li>
				<li><a href="../../develop/deploy-on-kubernetes">Deploy your services on Kubernetes</a></li>
				<li><a href="../../develop/running-as-a-java-program">Running your service as a Java program</a></li>
			</ul>
		</td>
	</tr>
	<tr>
		<td><b>Step 4: Observe your service</b></td>
		<td>
			As you build and run the micro services, you may need collecting and visualizing the metrics, collecting and storing logs and tracing transactions.
			<ul>
				<li>
					<a href="../../observability/observing-a-service">Observing a Service</a> with Prometheus.
				</li>
				<li>
					<a href="../../observability/logstash-kibana">Logging</a> using Logstash and Kibana
				</li>
			</ul>
		</td>
	</tr>
</table>
