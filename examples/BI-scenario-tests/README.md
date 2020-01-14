# BI-scenario-tests

The BI-Scenario-Tests folder contains the run.sh file and all the test suites. Each test suite contains the relevant Ballerina Project and the Test Project. As an example, the suit-0 contains the FTP Connector tests, suit-1 contains the SQS Connector tests. It will loop suite by suite. First it will go to the suit-0 and build the ballerina project and start the services. Then it will run the scenario tests in the Test Project. Finally it will stop the services and go to the next suite and execute the same. The run.sh file is below. It has been assumed that all the services in the Ballerina Projects started in port 9090. 

### Running the BI-scenario-tests

```shell
sh run.sh
```