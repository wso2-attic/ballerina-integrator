# Http to JMS protocol-switch Service

This template demonstrates a protocol-switch service which converts an http message to JMS and publishes to a queue.

## How to run the template

1. Alter the config file `src/protocol_switch_service/resources/ballerina.conf` and `<TEMPLATE_HOME>/Ballerina.toml` as per the requirement. 

2. Start an ActiveMQ broker instance.

3. Add the following jars from ACTIVE_MQ_HOME/lib to <TEMPLATE_HOME>/lib folder.

* activemq-client-{activemq-version}.jar
* geronimo-j2ee-management_1.1_spec-1.0.1.jar
* hawtbuf-1.11.jar"


4. Execute the following command in the project directory scatter_gather_service to run the service.
```bash
ballerina run --config src/protocol_switch_service/resources/ballerina.conf protocol_switch_service
```
5. Create a file named request.txt with the following content:
```
test payload!
```

6. Invoke the service with the following request. Use an HTTP client like cURL.
```bash
curl http://localhost:9090/sendTo/queue -H 'Content-Type:text/plain' -d @request.txt
```