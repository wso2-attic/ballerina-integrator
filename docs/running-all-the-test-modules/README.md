# How to run all the test modules?

This guide explains the instructions on running all the test modules without starting the backend and services manually. 

Let's focus this with an example. 

Assume we have ballerina healthcare service backend in ../healthcare/ folder. 

    -> ballerina_integrator
        -> examples
            -> guides
                -> services
                  -> healthcare-service

#### Requirement: 
We have set of integration tutorials in example-integration-tutorials folder which includes set of 
services(bal files) along with their tests. We need to start the services automatically while running the tests 
including the backend described above. 

#### Why do we need this?
We have different tutorials as below. Sometimes the same backend resource function can be invoked through 
different ballerina services. If the backend is running continuously, the data can be duplicated and it can result
in giving incorrect test outputs. 

Therefore, through this example we will guide to start the backend service along with the ballerina services in 
the beginning of the test module. At the end of the each test module, the services will be restarted. This 
prevents the data duplication. 

In the following example, the same test has been added to the both folders, which adds the same data. With the
above approach, they will not get affected from one another. 

Following is the folder structure for the example-integration-tutorials. 


    -> ballerina_integrator
      -> examples
        -> guides
          -> testing
            -> running-all-the-test-modules
              -> example-integration-tutorials
                -> tutorial-1
                  -> addDoctor.bal
                  -> tests
                -> tutorial-2
                  -> addDoctor.bal
                  -> tests



#### Steps
In tutorial-1, we have addDoctor.bal file and tests folder. Through our 'testAddDoctor' test function in addDoctorTest.bal file in tests folder, we invoke particular post resource in service running in 
http://localhost:9091/healthcare. 

Please note that the backend service runs in http://localhost:9090/healthcare. 

Therefore we need to import the backend service in our tests. 

In order to do that, please follow the below steps. 

1. Find the organization name in Ballerina.toml in healthcare-service resides in ../BallerinaWork/BallerinaInt/ballerina-integrator/examples/guides/services/healthcare-service. 

2. We need to build and add this to the ballerina home repository from project repository. 
Since all the .bal files in backend service reside in service folder we have to build as below. 

    Building the module

    ```
    ballerina build --skiptests <module_name>
    ```
    ```bash
    ballerina build --skiptests healthcare
    ```

    Adding it to the central repository
    ```
    ballerina install --no-build <module_name>
    ```
    ```
    ballerina install --no-build healthcare
    ```
    It will result in adding them to the home repository. 
    ```
    wso2/service:0.0.1 [project repo -> home repo]
    ```

3. Since the backend service use resources in util and daos we need to add them as above. 

4. Now we need to import the 'healthcare' module in our test classes. 
    ```
    import wso2/healthcare
    ```
5. Run all the test as below. 
folder location: 

    ../ballerina-integrator/examples/guides/testing/running-all-the-test-modules/example-integration-tutorials

    ```
    ballerina test
    ```

    You will see the tests running similar as below. 
    ```bash
    example-integration-tutorials IsuruUyanage$ ballerina test
    Compiling tests
    isuruuyanage/tutorial-1:0.0.1
    isuruuyanage/tutorial-2:0.0.1
    isuruuyanage/tutorial-3:0.0.1

    Running tests
    isuruuyanage/tutorial-1:0.0.1
    [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
    [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9091

    2019-06-23 22:34:23,135 INFO  [wso2/healthcare] - User error in addNewDoctor, Doctor Already Exists in the 
    system. 

      2 passing
      0 failing
      0 skipped

    [ballerina/http] stopped HTTP/WS endpoint 0.0.0.0:9090
    [ballerina/http] stopped HTTP/WS endpoint 0.0.0.0:9091
        isuruuyanage/tutorial-2:0.0.1
    [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9090
    [ballerina/http] started HTTP/WS endpoint 0.0.0.0:9092

    ```

#### Known Issues
In ballerina-0.991.0 release, there is an issue of getting increased the test execution once the number of modules get increased. 
This issue is fixed in 0.992.0-m2 version. 
