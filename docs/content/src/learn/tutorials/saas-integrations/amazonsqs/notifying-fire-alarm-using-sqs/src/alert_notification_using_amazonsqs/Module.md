Template for Amazon SQS Connector to notify alerts

# Amazon SQS Connector to notify alerts

This is a template for [Notifying fire alarm using SQS tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/amazonsqs/notifying-fire-alarm-using-sqs/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 

## Using the Template

Run the following command to pull the `alert_notification_using_amazonsqs` template from Ballerina Central.

```
$ ballerina pull wso2/alert_notification_using_amazonsqs
```

Create a new project.

```bash
$ ballerina new notifying-fire-alarm-using-sqs
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add -t wso2/alert_notification_using_amazonsqs alert_notification_using_amazonsqs
```

This automatically creates alert_notification_using_amazonsqs service for you inside the `src` directory of your project.  

## Testing

### 1. Developing the scenario

1. Configure parameters in `create_notification_queue.bal`, which will create a new queue. In order to create a queue initialize the `amazonsqs:Client` with configuration parameters and invoke the `createQueue` method of it. `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY` can be obtained from the Amazon account you have created. When a queue is created you can find the `ACCOUNT_NUMBER` of the SQS account.

2. Configure/develop `notify_fire.bal`, which will send periodic fire alerts to the created SQS queue. Instead of the `while` loop added, you can add some custom logic to trigger fire alarm. Create a client as described in step 1 and invoke `sendMessage` method to send alert message to the SQS queue.

3. Configure/develop `listen_to_fire_alarm.bal`, which will listen to the above created queue with polling. `sleep` method in the `while` loop can be called according to the polling interval. Then create the client as described in step 1 and invoke `receiveMessage` method. Depending on the `MaxNumberOfMessages` parameter set in the `attributes` array, maximum number of messages received per API invocation will be restricted. Each message can be accessed with `receiptHandle` value in the response. Once the message is read it can be deleted by invoking the `deleteMessage` method.

4. Configure/develop `main.bal`, which will implement the different workers for each of the above cases and run the system. There the workers can be replaced with the relevant code. `queueCreator` code should be called once to setup the queue. Code in the `fireNotifier` can be called from the fire alarm triggering side while `fireListener` should reside in the alarm polling/listening code.

### 2. Deployment

Once you are done with the development, you can deploy the scenario using any of the methods listed below.

```bash
$ ballerina build alert_notification_using_amazonsqs
```
This builds a JAR file (.jar) in the target folder. You can run this by using the `java -jar` command.

```bash
$ java -jar target/bin/alert_notification_using_amazonsqs.jar
```

You see the SQS queue creation, sending fire alerts to the queue, consuming process of queues and subsequent deletion 
process on console.
