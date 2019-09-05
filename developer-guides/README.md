# Building Ballerina-Integrator Project

Mainly the ballerina projects are run through a shell script pointed via the pom file which resides in <Ballerina-Integrator-HOME>/resources/run.sh file. 

```
<plugin>
   <groupId>org.codehaus.mojo</groupId>
   <artifactId>exec-maven-plugin</artifactId>
   <version>1.6.0</version>
   <executions>
       <execution>
           <id>my-exec</id>
           <phase>pre-integration-test</phase>
           <goals>
               <goal>exec</goal>
           </goals>
       </execution>
   </executions>
   <configuration>
      <executable>${project-home}/resources/run${script.extension}</executable>
   </configuration>
</plugin>
```

We shall focus on the following folder structure in path <HOME>/docs/learn directory.

```
|___overview.md
|___backends
|	|___healthcare-service
|		|___healthcare (module)
|___guides
|___integration-tutorials
|	|___exposing-several-services-as-a-single-service
|	|	|___tutorial(module)
|	|	|	|___health_care_service.bal	
|	|	|	|___tests
|	|___routing-requests-based-on-message-content
|	|	|___tutorial(module)
|	|	|	|___health_care_service.bal	
|	|	|	|___tests
|	|___sending-a-simple-message-to-a-service
|	|	|___tutorial(module)
|	|	|	|___health_care_service.bal	
|	|	|	|___tests
|	|___transforming-message-content
|	|	|___tutorial(module)
|	|	|	|___health_care_service.bal	
|	|	|	|___tests

```
We are building modules through run.sh file. 

As an example let’s say we need to build sending-a-simple-message-to-a-service project. 

1. We need to include the relative path to the project in config.properties file. 	
    ```
    path3=docs/learn/integration-tutorials/sending-a-simple-message-to-a-service
    ```

2. We need to add the following in the <HOME>/resources/run.sh file. 
	- executionNameList - project name
	- executionPathList - relevant path in the <HOME>/resources/config.properties file
	- moduleList - module name
	
  Eg:
```
executionNameList=("sending-a-simple-message-to-a-service" ) 
executionPathList=($path4)
moduleList=("tutorial")
```
 

## Points to note
- If the 0th element in the executionNameList array is Project name, executionPathList array and in the moduleList arrays the 0th element should be relevant path and the module name. 

- Currently the Integration Tutorials, Healthcare-service and some of the guides have been added to the above. If you have a ballerina project to be built, above configurations need to be done in HOME/resources/run.sh file and HOME/resources/config.properties file. 

- The log of the complete test execution can be found at HOME/completeTestResults.log file. 

- Java projects can be built simply pointing it in the main pom file under modules. 


### Building the Ballerina-Integrator Project

```
mvn clean install
```



