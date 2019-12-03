Template for Scatter-Gather Flow using Ballerina

# Scatter-Gather Flow using Ballerina

This is a template for the [Scatter-gather Flow Control tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/scatter-gather-flow/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `scatter_gather_flow` template from Ballerina Central.

```
$ ballerina pull wso2/scatter_gather_flow
```

Create a new project.

```bash
$ ballerina new scatter-gather-flow
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/scatter_gather_flow scatter_gather_flow
```

This automatically creates scatter_gather_flow service for you inside the `src` directory of your project.  

## Testing

### Before you begin

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. This file should have following configurations. Add the FTP server configurations to the file.

```
FTP_HOST = "<IP address of the FTP server>"
FTP_PORT = "<port used to connect with the server (default value 21)>"
FTP_USER = "<Username of the FTP server >"
FTP_PASSWORD = "<Password of the FTP server>"
```

Before writing the service, let's create two CSV files `employees1.csv` and `employees2.csv` with the following content and upload to an FTP server.

```csv
empId,firstName,lastName,joinedDate
100,Lois,Walker,11/24/2003
101,Brenda,Robinson,7/27/2008
102,Joe,Robinson,8/3/2016
103,Diane,Evans,4/16/1999
104,Benjamin,Russell,7/25/2013
```

```csv
empId,firstName,lastName,joinedDate
105,Nancy,Baker,7/22/2005
106,Carol,Murphy,9/14/2016
107,Frances,Young,1/28/1983
108,Diana,Peterson,4/27/1994
109,Ralph,Flores,2/17/2014
```

### Invoking the service

Let’s build the module. Navigate to the project root directory and execute the following command.
```
$ ballerina build scatter_gather_flow
```

The build command would create an executable .jar file. Now run the .jar file created in the above step using the following command. Path to the ballerina.conf file can be provided using the --b7a.config.file option.
```
$ java -jar target/bin/scatter_gather_flow.jar --b7a.config.file=path/to/ballerina.conf/file
```

Now we can see that the service has started on port 9090.
