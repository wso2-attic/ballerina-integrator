# Logging using Logstash and Kibana

Ballerina has a log module for logging to the console. You can import the `ballerina/log` module and start logging. The following section will describe how to search, analyze, and visualize logs in real time using [Elastic Stack](https://www.elastic.co/).

To understand how you can track logging for Ballerina services, let’s consider a service that converts JSON to XML.

![alt text](../../assets/img/logstash-kibana.png)

## Set up the project 

1. Open VS Code.
   > **Tip**: Download and install [VS Code](https://code.visualstudio.com/Download) if you do not have it already. Find the extension for Ballerina in the VS Code marketplace if you do not have it. This extension is called `Ballerina`. For instructions on installing and using it, see [The Visual Studio Code Extension](https://ballerina.io/learn/tools-ides/vscode-plugin/).

2. Press `Command + Shift + P` in Mac or `Ctrl + Shift + P` in Linux and the following page appears.

![alt text](../../assets/img/vs-code-landing.png)

3. Select the template to transform XML messages to JSON and your project will load.

## Set up your environment

### Increasing performance for Docker for Linux

If you run on Linux you may have to increase the `vm.max_map_count` for the Elasticsearch container to start. Execute the following command to do that.

```
$ sudo sysctl -w vm.max_map_count=262144

```

### Increasing performance for latest Docker For Mac:

If you are on a more recent OSX version, do the following.

```
$ screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty

```

On the blank screen, press RETURN.

Then configure the sysctl setting as you would for Linux:

```
sysctl -w vm.max_map_count=262144

```

Exit by pressing Control+A and Control+\.

### Increasing performance for older versions of Docker for Mac

If you are on an older OSX version, do the following.

The `vm_max_map_count` setting must be set within the xhyve virtual machine:

```
$ screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty

```

If it asks you for a username and password, log in with root and no password.

If it just has a blank screen, press RETURN.

Then configure the sysctl setting as you would for Linux:

```
$ sudo sysctl -w vm.max_map_count=262144

```

Exit by pressing Control+A and Control+\.

### Increasing performance of Docker for Windows

The vm.max_map_count setting must be set via docker-machine:

```
docker-machine ssh
sudo sysctl -w vm.max_map_count=262144

```

## Set up Kibana

1. Navigate to the .bal file in the template project and start the Ballerina service with the following command.

   ```
   $ nohup ballerina run main.bal &> ballerina.log&

   ```

   > **NOTE**: This will write the console log to the `ballerina.log` file in the same directory

2. Start Elasticsearch using the following command.

   ```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1 
   ```

   > **NOTE**: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
3. Start Kibana plugin for data visualization with Elasticsearch.

   ```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.5.1     
   ```

## Set up logstash

Configure logstash to format the Ballerina logs

1. Create a file named `logstash.conf` with the following content
   ```
   input {  
    beats{ 
        port => 5044 
    }  
   }
   
   filter {  
    grok{  
        match => { 
	    "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	    \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
        }  
    }  
   }   
   
   output {  
    elasticsearch{  
        hosts => "elasticsearch:9200"  
        index => "store"  
        document_type => "store_logs"  
    }  
   }  
   ```

2. Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
3. Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
   ```
   $ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
   -it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
   -p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
   ```
  
## Configure filebeat to ship the Ballerina logs
    
1. Create a file named `filebeat.yml` with the following content

   ```
   filebeat.prospectors:
   - type: log
     paths:
       - /usr/share/filebeat/ballerina.log
   output.logstash:
     hosts: ["logstash:5044"]  
   ```
   
   > **NOTE**: Modify the ownership of filebeat.yml file using `$chmod go-w filebeat.yml` 

2. Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
3. Start the logstash container, replace the {SAMPLE_ROOT} with your directory name
     
   ```
   $ docker run -v {SAMPLE_ROOT}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
   -v /Users/sam/Documents/ballerina-integrator/qsg/MyProject3/src/MyModule/ballerina.log:/usr/share\
   /filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
   ```

## Visualizing logs on Kibana

Access Kibana to visualize the logs using following URL.

```
   http://localhost:5601 
```
![alt text](../../assets/img/logstash-kibana-visual.png)
