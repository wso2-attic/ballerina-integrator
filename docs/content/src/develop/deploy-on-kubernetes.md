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
import ballerina/config;
import ballerina/http; 
import ballerina/mysql; 
import ballerinax/kubernetes;

// Create SQL endpoint to MySQL database
mysql:Client employeeDB = new ({
    host:config:getAsString("db-host"),
    port:3306,
    name:config:getAsString("db"),
    username:config:getAsString("db-username"),
    password:config:getAsString("db-password")
});

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-employee-database-service",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-employee-database-service"
}
listener http:Listener ep = new (9090, config = {
    secureSocket:{
        keyStore:{
            path:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password:config:getAsString("key-store-password")
        },
        trustStore:{
            path:"${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password:config:getAsString("trust-store-password")
        }
    }
});

@kubernetes:ConfigMap {
    ballerinaConf:"conf/data-service.toml"
}
@kubernetes:Deployment {
    image:"ballerina.guides.io/employee_database_service:v1.0",
    name:"ballerina-guides-employee-database-service",
    copyFiles:[{target:"/ballerina/runtime/bre/lib",
                source:"conf/mysql-connector-java-8.0.11.jar"}]
}
@http:ServiceConfig {
    basePath:"/records"
}
service employee_data_service on ep {
```

Sample content of `data-service.toml`:

```toml
# Ballerina database config file
db-host = "mysql-server"
db = "EMPLOYEE_RECORDS"
db-username = "root"
db-password = "root"
key-store-password = "abc123"
trust-store-password = "xyz123"
```

Here we have used `@kubernetes:Deployment` to specify the Docker image name that will be created as part of building this service. The `CopyFiles` field is used to copy the MySQL JAR file into the Ballerina `bre/lib` folder.

The `@kubernetes:Service {}` annotation will create a Kubernetes service that will expose the Ballerina service running on a Pod.

In addition, you can use `@kubernetes:Ingress`, which is the external interface to access your service (with path / and host name `ballerina.guides.io`).

Minikube users please see the [Kubernetes Extension samples](https://github.com/ballerinax/kubernetes/tree/master/samples) for additional configurations required for Minikube.

Now you can use the following command to build the Ballerina service that we developed above. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.

```bash
$ ballerina build data_backed_service.bal
@kubernetes:Service                     - complete 1/1
@kubernetes:Ingress                     - complete 1/1
@kubernetes:Secret                      - complete 1/1
@kubernetes:ConfigMap                	- complete 1/1
@kubernetes:Docker                      - complete 3/3 
@kubernetes:Deployment                  - complete 1/1

Run the following command to deploy Kubernetes artifacts: 
kubectl apply -f ./kubernetes/

```
You can use the `docker images` command to verify that the Docker image that we specified in `@kubernetes:Deployment` was created. The Kubernetes artifacts related to your service will be generated in addition to the `.balx` file.

```bash
$ tree
├── conf
│   ├── ballerina.conf
│   └── mysql-connector-java-8.0.11.jar
├── data_backed_service.bal
├── data_backed_service.balx
└── kubernetes
    ├── data_backed_service_config_map.yaml
    ├── data_backed_service_deployment.yaml
    ├── data_backed_service_ingress.yaml
    ├── data_backed_service_secret.yaml
    ├── data_backed_service_svc.yaml
    └── docker
        ├── Dockerfile
        └── mysql-connector-java-8.0.11.jar

```

Now you can create the Kubernetes deployment using:

```bash
$ kubectl apply -f ./kubernetes 

configmap "employee-data-service-ballerina-conf-config-map" created
deployment "ballerina-guides-employee-database-service" created
ingress "ballerina-guides-employee-database-service" created
secret "listener-secure-socket" created
service "ballerina-guides-employee-database-service" created
```
You can verify Kubernetes deployment, service, and ingress are running properly by using the following Kubernetes commands.

```bash
$ kubectl get pods
NAME                                                          READY     STATUS    RESTARTS   AGE
ballerina-guides-employee-database-service-57479b7c67-l5v9k   1/1       Running     0          26s
```
This is the container based on the deployment annotation. This container has the `.balx` file, secrets, config-maps, and dependencies wrapped within. 

```bash
$ kubectl get svc
NAME                                         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
ballerina-guides-employee-database-service   NodePort    10.96.24.77   <none>        9090:30281/TCP   51s
```
This is the Kubernetes service that exposes the listener endpoint.

```bash
$ kubectl get ingress
NAME                                         HOSTS                 ADDRESS   PORTS     AGE
ballerina-guides-employee-database-service   ballerina.guides.io             80, 443   1m
```
This is the Kubernetes nginx rule that exposes the hostname to the outside world.

```bash
$ kubectl get secrets
NAME                     TYPE                                  DATA      AGE
listener-secure-socket   Opaque                                2         1m
```
The secrets are generated automatically for endpoint keystores and truststores. This secret is mounted to `${ballerina_home}` of the container.

```bash
$ kubectl get configmap
NAME                                              DATA      AGE
employee-data-service-ballerina-conf-config-map   1         2m
```
This is the config-map created for the `ballerina.conf` file, as the `ballerinaConf:"./conf/data-service.toml"` attribute is used. At run time, it is an equivalent of:
```bash
$ ballerina run --config ./conf/data-service.toml <source>.balx 
```
The Kubernetes extension automatically passes the config file to the Ballerina program.

If everything is successfully deployed, you can invoke the service either via Node port or ingress.

**Access via Node Port:**
```bash
$ curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://localhost:<Node_Port>/records/employee" -H "Content-Type:application/json" 
```

**Access via Ingress:**

Add an `/etc/hosts` entry to match hostname.

```bash
127.0.0.1 ballerina.guides.io
```
Access the service:

```bash
$ curl -v -X POST -d '{"name":"Alice", "age":20,"ssn":123456789,"employeeId":1}' \
"http://ballerina.guides.io/records/employee" -H "Content-Type:application/json"
```   
    
##### Supported Kubernetes Annotations

**@kubernetes:Deployment{}**
- Supported with Ballerina services or endpoints.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the deployment|\<outputfilename\>-deployment|
|labels|Labels for deployment|"app: \<outputfilename\>"|
|replicas|Number of replicas|1|
|enableLiveness|Enable or disable liveness probe|disable|
|initialDelaySeconds|Initial delay in seconds before performing the first probe|10s|
|periodSeconds|Liveness probe interval|5s|
|livenessPort|Port that the liveness probe checks|\<ServicePort\>|
|imagePullPolicy|Docker image pull policy|IfNotPresent|
|image|Docker image with tag|<output file name>:latest|
|env|List of environment variables|null|
|buildImage|Building Docker image|true|
|copyFiles|Copy external files for Docker image|null|
|dockerHost|Docker host IP and Docker PORT (e.g., "tcp://192.168.99.100:2376")|null|
|dockerCertPath|Docker cert path|null|
|push|Push Docker image to registry. This can only be true if image build is true.|false|
|username|Username for the Docker registry|null|
|password|Password for the Docker registry|null|
|baseImage|Base image to create the Docker image|ballerina/ballerina:latest|
|singleYAML|Generate a single yaml file for all k8s resources|false|

**@kubernetes:Service{}**
- Supported with Ballerina endpoints.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the service|\<ballerina service name\>-service|
|labels|Labels for the service|"app: \<outputfilename\>"|
|serviceType|Service type of the service|ClusterIP|
|port|Service port|Port of the Ballerina service|

**@kubernetes:Ingress{}**
- Supported with Ballerina endpoints.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of Ingress|\<ballerina service name\>-ingress
|labels|Labels for service|"app: \<outputfilename\>"
|hostname|Host name of Ingress|\<ballerina service name\>.com
|path|Resource path.|/
|targetPath|This is used for URL rewrite.|null
|ingressClass|Ingress class|nginx
|enableTLS|Enable ingress TLS|false

**@kubernetes:HPA{}**
- Supported with Ballerina services.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the Horizontal Pod Autoscaler|\<ballerina service name\>-hpa|
|labels|Labels for service|"app: \<outputfilename\>"|
|minReplicas|Minimum number of replicas|No of replicas in deployment|
|maxReplicas|Maximum number of replicas|minReplicas+1|
|cpuPrecentage|CPU percentage to start scaling|50|

**@kubernetes:Secret{}**
- Supported with Ballerina services.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the secret volume mount|\<service_name\>-secret|
|mountPath|Path to mount on container|null|
|readOnly|Is mount read only|true|
|data|Paths to data files|null|

**@kubernetes:ConfigMap{}**
- Supported with Ballerina services.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the configmap volume mount|\<service_name\>-config-map|
|mountPath|Path to mount on container|null|
|readOnly|Is mount read only|true|
|ballerinaConf|Ballerina conf file location|null|
|data|Paths to data files|null|

**@kubernetes:PersistentVolumeClaim{}**
- Supported with Ballerina services.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name|Name of the volume mount|null|
|mountPath|Path to mount on container|null|
|readOnly|Is mount read only|false|
|accessMode|Access mode|ReadWriteOnce|
|volumeClaimSize|Size of the volume claim|null|

**@kubernetes:Job{}**
- Supported with the Ballerina `main()` function.

|**Annotation Name**|**Description**|**Default value**|
|--|--|--|
|name| Name of the job|\<output file name\>-job|
|labels| Labels for job|"app: \<outputfilename\>"|
|restartPolicy| Restart policy|Never|
|backoffLimit| Restart tries before termination|3|
|activeDeadlineSeconds| Active deadline seconds|20|
|schedule| Schedule for cron jobs|none|
|imagePullPolicy|Docker image pull policy|IfNotPresent|
|image|Docker image with tag|\<output file name\>:latest|
|env|List of environment variables|null|
|buildImage|Building Docker image|true|
|dockerHost|Docker host IP and Docker PORT (e.g., "tcp://192.168.99.100:2376")|null|
|dockerCertPath|Docker cert path|null|
|push|Push Docker image to registry. This can only be true if image build is true.|false|
|username|Username for the Docker registry|null|
|password|Password for the Docker registry|null|
|baseImage|Base image to create the Docker image|ballerina/ballerina:latest|
  
