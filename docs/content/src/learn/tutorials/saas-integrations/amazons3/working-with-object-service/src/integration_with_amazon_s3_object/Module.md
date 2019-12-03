Template for Amazon S3 Object Service 

# Working with Amazon S3 Object Service 

This is a template for [Working with Amazon S3 Object Service tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/saas-integrations/amazons3/working-with-object-service/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `integration_with_amazon_s3_object` template from Ballerina Central.

```
$ ballerina pull wso2/integration_with_amazon_s3_object
```

Create a new project.

```bash
$ ballerina new working-with-object-service
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/integration_with_amazon_s3_object integration_with_amazon_s3_object
```

This automatically creates integration_with_amazon_s3_object service for you inside the `src` directory of your project.  

## Testing

### 1. Set up credentials for accessing Amazon S3

- Visit [Amazon S3](https://aws.amazon.com/s3/) and create an Amazon S3 account.

- Create a new access key, which includes a new secret access key.
        - To create a new secret access key for your root account, use the [security credentials](https://console.aws.amazon.com/iam/home?#security_credential) page. Expand the Access Keys section, and then click Create New Root Key.

-  To create a new secret access key for an IAM user, open the [IAM console](https://console.aws.amazon.com/iam/home?region=us-east-1#home). Click **Users** in the **Details** pane, click the appropriate IAM user, and then click **Create Access Key** on the **Security Credentials** tab.
   
- Download the newly created credentials, when prompted to do so in the key creation wizard.

### 2. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the obtained SAmazon S3 configurations to the file.

`REGION` is the AWS Region where you require the bucket to be created. (e.g.: `eu-west-1`)

```
ACCESS_KEY_ID="<Amazon S3 key ID>"
SECRET_ACCESS_KEY="<Amazon S3 secret key>"
REGION="<Amazon S3 region>"
```

## Testing 

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build integration-with-amazon-s3-object
```

This creates the executables. Now run the `integration-with-amazon-s3-object.jar` file created in the above step.

```bash
$ java -jar target/bin/integration-with-amazon-s3-object.jar
```
You will see the following log upon the successful invocation of the service.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9090
```
