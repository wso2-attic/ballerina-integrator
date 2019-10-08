# Amazon S3 Bucket Service

Ballerina is an open-source programming language that empowers developers to integrate their system easily with the 
support of connectors. In this guide, we are mainly focusing on connecting to the Amazon Simple Storage Service API to create, store, download, and use data with other services.  

The `wso2/amazons3` module allows you to perform the following operations.
* Create Bucket
* List Buckets
* Create Object
* List Objects
* Get Object
* Delete Object
* Delete Bucket

This example explains how to use the S3 client to connect with the Amazon S3 instance and to create an Amazon S3 bucket.

You can find other integrations modules from [wso2-ballerina](https://github.com/wso2-ballerina) GitHub organization.

## What you'll build

This application connects with the Amazon S3 API and creates a new bucket on Amazon S3 instance with the provided name, gets the available buckets and deletes the specified bucket.

![exposing Amazon S3 as a service](../../../../../assets/img/amazon-s3-bucket-service)

<!-- INCLUDE_MD: ../../../../../tutorial-prerequisites.md -->

<!-- INCLUDE_MD: ../../../../../tutorial-get-the-code.md -->

## Implementation

A Ballerina project is created for the integration use case explained above. Please follow the steps given 
below to create the project and modules. You can learn about the Ballerina project and modules in this 
[guide](../../../../../develop/managing-ballerina-code/).

#### 1. Create a new project.

```bash
$ ballerina new amazon-s3-bucket-service
```

#### 2. Create a module.

```bash
$ ballerina add integration-with-amazon-s3-bucket
```

The project structure is created as indicated below.

```
amazon-s3-bucket-service
    ├── Ballerina.toml
    └── src
        └── integration-with-amazon-s3-bucket
            ├── Module.md
            ├── main.bal
            ├── resources
            └── tests
                └── resources
```

#### 3. Set up credentials for accessing Amazon S3

- Visit [Amazon S3](https://aws.amazon.com/s3/) and create an Amazon S3 account.

- Create a new access key, which includes a new secret access key.
        - To create a new secret access key for your root account, use the [security credentials](https://console.aws.amazon.com/iam/home?#security_credential) page. Expand the Access Keys section, and then click Create New Root Key.

-  To create a new secret access key for an IAM user, open the [IAM console](https://console.aws.amazon.com/iam/home?region=us-east-1#home). Click **Users** in the **Details** pane, click the appropriate IAM user, and then click **Create Access Key** on the **Security Credentials** tab.
- Download the newly created credentials, when prompted to do so in the key creation wizard.

 ![Amazon S3 Guide Implementation](resources/s3_connector_guide_implementation.svg "Amazon S3 Guide Implementation")


#### 4. Add project configurations file

Add the project configuration file by creating a `ballerina.conf` file under the root path of the project structure. 
This file should have following configurations. Add the obtained Amazon S3 configurations to the file.

```
ACCESS_KEY_ID="<Amazon S3 key ID>"<br/>
SECRET_ACCESS_KEY="<Amazon S3 secret key>"<br/>
REGION="<Amazon S3 region>"<br/>
BUCKET_NAME="<Amazon S3 bucket name>"<br/>
TRUST_STORE_PATH="<Truststore file location>"<br/>
TRUST_STORE_PASSWORD="<Truststore password>"<br/>
```

#### 5. Write the integration
Open the project with VS Code. The integration implementation is written in the `src/integration-with-amazon-s3-bucket/main.bal` file.

<!-- INCLUDE_CODE: src/integration-with-amazon-s3-bucket/main.bal -->

### Testing 

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build integration-with-amazon-s3-bucket
```

This creates the executables. Now run the `integration-with-amazon-s3-bucket.jar` file created in the above step.

```bash
$ java -jar target/bin/integration-with-amazon-s3-bucket.jar
```

You will see the following service log after successfully invoking the service.

```log
[ballerina/http] started HTTP/WS listener 0.0.0.0:9091
```

### Testing the create bucket service 

- Invoke the following curl request to create a new bucket.
```bash
curl -v -X POST http://localhost:9091/amazons3/imageStore/firstbalbucket
```
You see the response as follows after successfully creating the Amazon S3 bucket.
```
firstbalbucket created on Amazon S3.
```

### Testing the list bucket service 

- Invoke the following curl request to list buckets.
```
curl -X GET http://localhost:9091/amazons3/imageStore

```

```json
{"name":"firstbalbucket", "creationDate":"2019-10-04T11:04:30.000Z"}
```

#### Test delete Bucket service

- Invoke the following curl request to delete the above bucket.
```
curl -v -X DELETE http://localhost:9091/amazons3/imageStore/firstbalbucket
```
You see the response as follows:
```
firstbalbucket deleted from Amazon S3
```
