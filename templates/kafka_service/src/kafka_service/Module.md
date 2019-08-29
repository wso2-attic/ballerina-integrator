# Kafka Service Template

This template demonstrates how to use Ballerina Kafka connector.

## How to run the template

### Initializing Ballerina
- Open the terminal from the created template and run the Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Invoking the Kafka service

1. Alter the config file `src/kafka_service/resources/ballerina.conf` as per the requirement.

2. Execute the following command from to run the service.
```bash
ballerina run --config src/kafka_service/resources/ballerina.conf kafka_service
```
