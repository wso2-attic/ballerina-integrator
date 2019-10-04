#### Kubernetes-Based Deployment

The Kubernetes builder extension offers native support for running Ballerina programs on Kubernetes with the use of annotations that you can include as part of your service code. Also, it will take care of the creation of the Docker images, so you don't need to explicitly create Docker images prior to deployment on Kubernetes.

The following Kubernetes configurations are supported:
- Kubernetes deployment support
- Kubernetes service support
- Kubernetes liveness probe support
- Kubernetes ingress support
- Kubernetes horizontal pod autoscaler support
- Docker image generation
- Docker push support with remote Docker registry
- Kubernetes secret support
- Kubernetes config map support
- Kubernetes persistent volume claim support

The following Ballerina code section explains how you can use some of these Kubernetes capabilities by using Kubernetes annotation support in Ballerina. 
Full example can be found at [Database Interaction Guide](https://ballerina.io/learn/by-guide/data-backed-service/)

```ballerina
import ballerina/http;
import ballerina/log;
import ballerina/jsonutils;
import ballerina/xmlutils;

import ballerina/kubernetes;

// Endpoint for the backend service.
http:Client healthcareEndpoint = new("https://reqres.in");
// Constants for request paths.
const BACKEND_EP_PATH = "/api/users";

@kubernetes:Ingress {
    hostname:"ei.ballerina.integrator.io",
    name:"science-lab-service",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"science-lab-service"
}
// @kubernetes:Ingress{} annotation to a service is only supported when service is bind to an anonymous listener
listener http:Listener scienceLab = new(8080);

@kubernetes:Deployment {
    image:"index.docker.io/$env{DOCKER_USERNAME}/sciencelab:v2.0.0",
    name:"science-lab-service"
}
@http:ServiceConfig {
    basePath: "/laboratory"
}
service scienceLabService on scienceLab {
```

Here we have used `@kubernetes:Deployment` to specify the Docker image name that will be created as part of building this service. 

The `@kubernetes:Service {}` annotation will create a Kubernetes service that will expose the Ballerina service running on a Pod.

In addition, you can use `@kubernetes:Ingress`, which is the external interface to access your service (with path / and host name `ei.ballerina.integrator.io`).

Minikube users please see the [Kubernetes Extension samples](https://github.com/ballerinax/kubernetes/tree/master/samples) for additional configurations required for Minikube.

Now you can use the following command to build the Ballerina service that we developed above. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.

```bash
$ ballerina build MyModule
Compiling source
	sam/MyModule:0.1.0

Creating balos
	target/balo/MyModule-2019r3-any-0.1.0.balo

Running tests
    sam/MyModule:0.1.0
	No tests found


Generating executables
	target/bin/MyModule.jar

Generating artifacts...

	@kubernetes:Service 			 - complete 1/1
	@kubernetes:Ingress 			 - complete 1/1
	@kubernetes:Deployment 			 - complete 1/1
	@kubernetes:Docker 			 - complete 2/2 
	@kubernetes:Helm 			 - complete 1/1

	Run the following command to deploy the Kubernetes artifacts: 
	kubectl apply -f /home/sam/ballerina/MyProject/target/kubernetes/MyModule

	Run the following command to install the application using Helm: 
	helm install --name science-lab-service /home/sam/ballerina/MyProject/target/kubernetes/MyModule/science-lab-service

```
You can use the `docker images` command to verify that the Docker image that we specified in `@kubernetes:Deployment` was created. The Kubernetes artifacts related to your service will be generated in addition to the `.jar` file.

```bash
$ tree
.
├── ballerina-internal.log
├── Ballerina.lock
├── Ballerina.toml
├── src
│   └── MyModule
│       ├── main.bal
│       ├── Module.md
│       └── resources
│           └── ballerina.conf
└── target
    ├── balo
    │   └── MyModule-2019r3-any-0.1.0.balo
    ├── bin
    │   └── MyModule.jar
    ├── caches
    │   ├── bir_cache
    │   │   └── indika
    │   │       └── MyModule
    │   │           └── 0.1.0
    │   │               └── MyModule.bir
    │   └── jar_cache
    │       └── indika
    │           └── MyModule
    │               └── 0.1.0
    │                   └── sam-MyModule-0.1.0.jar
    ├── docker
    │   └── MyModule
    │       └── Dockerfile
    ├── kubernetes
    │   └── MyModule
    │       ├── MyModule.yaml
    │       └── science-lab-service
    │           ├── Chart.yaml
    │           └── templates
    │               └── MyModule.yaml

```

Now you can create the Kubernetes deployment using:

```bash
$ kubectl apply -f /home/sam/ballerina/MyProject/target/kubernetes/MyModule

service/science-lab-service created
ingress.extensions/science-lab-service created
deployment.apps/science-lab-service created
```
You can verify Kubernetes deployment, service, and ingress are running properly by using the following Kubernetes commands.

```bash
$ kubectl get pods
NAME                                                    READY   STATUS    RESTARTS   AGE
science-lab-service-7957c567f-cn78q                     1/1     Running   0          41m
```
This is the container based on the deployment annotation. This container has the `.balx` file, secrets, config-maps, and dependencies wrapped within. 

```bash
$ kubectl get svc
NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
science-lab-service                 NodePort    10.104.63.28    <none>        8080:31821/TCP   42m
```
This is the Kubernetes service that exposes the listener endpoint.

```bash
$ kubectl get ingress
NAME                  HOSTS                        ADDRESS     PORTS   AGE
science-lab-service   ei.ballerina.integrator.io   10.0.2.15   80      42m
```
This is the Kubernetes nginx rule that exposes the hostname to the outside world.

The Kubernetes extension automatically passes the config file to the Ballerina program.

If everything is successfully deployed, you can invoke the service either via Node port or ingress.

**Access via Node Port:**

> **Tip**: Please get the Minikube IP if the Kubernetes cluster is running on Minikube.
```bash
$ minikube ip
```

Invoke the service with a cURL command:
 
```bash
$ curl -X POST -d '<user><name>Sam</name><job>Scientist</job></user>'  http://<localhost/minikube_ip>:9092/laboratory/user  -H "Content-Type: text/xml"  
```

**Access via Ingress:**

Add an `/etc/hosts` entry to match hostname.
> **Tip**: Please get the Minikube IP if the Kubernetes cluster is running on Minikube.

```bash
127.0.0.1 ei.ballerina.integrator.io
```
Access the service:

```bash
$ curl -X POST -d '<user><name>Sam</name><job>Scientist</job></user>'  http://ei.ballerina.integrator.io/laboratory/user  -H "Content-Type: text/xml"  
```
    
##### Supported Kubernetes Annotations
You can find more details about Kubernetes support from [here](https://github.com/ballerinax/kubernetes#ballerina-kubernetes-extension).
