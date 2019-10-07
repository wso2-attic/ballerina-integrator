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

```ballerina
import ballerina/http;
import ballerina/log;
import ballerina/kubernetes;

http:Client grandOakHospital = new("http://localhost:9091/grandOak");
http:Client pineValleyHospital = new("http://localhost:9092/pineValley");

@kubernetes:Ingress {
    hostname:"ei.ballerina.integrator.io",
    name:"healthcare-service",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"science-lab-service"
}
// @kubernetes:Ingress{} annotation to a service is only supported when service is bind to an anonymous listener
listener http:Listener healthcareEndpoint = new(9090);

@kubernetes:Deployment {
    image:"index.docker.io/${DOCKER_USERNAME}/healthcare:v2.0.0",
    name:"science-lab-service"
}
@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcare on healthcareEndpoint {

    @http:ResourceConfig {
        path: "/doctor/{doctorType}"
    }
    resource function getDoctors(http:Caller caller, http:Request request, string doctorType) returns error? {
        json grandOakDoctors = {};
        json pineValleyDoctors = {};
        var grandOakResponse = grandOakHospital->get(<@untained> ("/doctors/" + doctorType));
        var pineValleyResponse = pineValleyHospital->post("/doctors", <@untained>  {doctorType: doctorType});
```

Here we have used `@kubernetes:Deployment` to specify the Docker image name that will be created as part of building this service. 

The `@kubernetes:Service {}` annotation will create a Kubernetes service that will expose the Ballerina service running on a Pod.

In addition, you can use `@kubernetes:Ingress`, which is the external interface to access your service (with path / and host name `ei.ballerina.integrator.io`).

Minikube users please see the [Kubernetes Extension samples](https://github.com/ballerinax/kubernetes/tree/master/samples) for additional configurations required for Minikube.

Now you can use the following command to build the Ballerina service that we developed above. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.

```bash
$ ballerina build healthcare_service
```

You get the following output.

```bash
Compiling source
	wso2/healthcare_service:0.1.0

Creating balos
	target/balo/healthcare_service-2019r3-any-0.1.0.balo

Running tests
    wso2/healthcare_service:0.1.0
	No tests found


Generating executables
	target/bin/healthcare_service.jar

Generating artifacts...

	@kubernetes:Service 			 - complete 1/1
	@kubernetes:Ingress 			 - complete 1/1
	@kubernetes:Deployment 			 - complete 1/1
	@kubernetes:Docker 			 - complete 2/2 
	@kubernetes:Helm 			 - complete 1/1

	Run the following command to deploy the Kubernetes artifacts: 
	kubectl apply -f /home/user/ballerina/quick-start-guide/target/kubernetes/healthcare_service

	Run the following command to install the application using Helm: 
	helm install --name healthcare-service /home/user/ballerina/quick-start-guide/target/kubernetes/healthcare_service/healthcare-service
```
You can use the `docker images` command to verify that the Docker image that we specified in `@kubernetes:Deployment` was created. The Kubernetes artifacts related to your service will be generated in addition to the `.jar` file.

```bash
$ tree
.
├── Ballerina.lock
├── Ballerina.toml
├── src
│   └── healthcare_service
│       ├── grandOak.bal
│       ├── healthcare_service.bal
│       ├── Module.md
│       ├── pineValley.bal
│       ├── resources
│       ├── tests
│       │   └── resources
│       └── utils.bal
└── target
    ├── balo
    │   └── healthcare_service-2019r3-any-0.1.0.balo
    ├── bin
    │   └── healthcare_service.jar
    ├── caches
    │   ├── bir_cache
    │   │   └── wso2
    │   │       └── healthcare_service
    │   │           └── 0.1.0
    │   │               └── healthcare_service.bir
    │   └── jar_cache
    │       └── wso2
    │           └── healthcare_service
    │               └── 0.1.0
    │                   └── wso2-healthcare_service-0.1.0.jar
    ├── docker
    │   └── healthcare_service
    │       └── Dockerfile
    └── kubernetes
        └── healthcare_service
            ├── healthcare_service.yaml
            └── healthcare-service
                ├── Chart.yaml
                └── templates
                    └── healthcare_service.yaml
```

Now you can create the Kubernetes deployment using:

```bash
$ kubectl apply -f /home/user/ballerina/quick-start-guide/target/kubernetes/healthcare_service

service/healthcare-service created
ingress.extensions/healthcare-service created
deployment.apps/healthcare-service created
```
You can verify Kubernetes deployment, service, and ingress are running properly by using the following Kubernetes commands.

```bash
$ kubectl get pods
NAME                                                    READY   STATUS    RESTARTS   AGE
healthcare-service-649858b85c-f8c49                     1/1     Running   0          56s
```
This is the container based on the deployment annotation. This container has the `.balx` file, secrets, config-maps, and dependencies wrapped within. 

```bash
$ kubectl get svc
NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
healthcare-service                  NodePort    10.98.9.69      <none>        9090:32367/TCP   77s
```
This is the Kubernetes service that exposes the listener endpoint.

```bash
$ kubectl get ingress
NAME                  HOSTS                        ADDRESS     PORTS   AGE
healthcare-service    ei.ballerina.integrator.io   10.0.2.15   80      103s
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
$ curl  http://<localhost/minikube_ip>:32367/healthcare/doctor/physician  
```

**Access via Ingress:**

Add an `/etc/hosts` entry to match hostname.
> **Tip**: Please get the Minikube IP if the Kubernetes cluster is running on Minikube.

```bash
127.0.0.1 ei.ballerina.integrator.io
```
Access the service:

```bash
$ curl  http://ei.ballerina.integrator.io/healthcare/doctor/physician   
```
    
##### Supported Kubernetes Annotations
You can find more details about Kubernetes support from [here](https://github.com/ballerinax/kubernetes#ballerina-kubernetes-extension).
