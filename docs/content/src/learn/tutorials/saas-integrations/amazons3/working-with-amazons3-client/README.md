# Working with Amazon S3 client

## Overview
The Ballerina Amazon S3 client enables you to connect to the Amazon Simple Storage Service API. It allows users to interact 
with the Amazon S3 API to create, store, download, and use data with other services. 

This example explains how to use the S3 client to connect with the Amazon S3 instance and perform the following operations:
* Create Bucket
* List Buckets
* Create Object
* List Objects
* Get Object
* Delete Object
* Delete Bucket

## Prerequisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- Obtain the credentials such as Access Key and Secret Access Key (API Secret) from Amazon S3 by following the steps below:
    1. Create an Amazon S3 account by visiting [https://aws.amazon.com/s3/](https://aws.amazon.com/s3/).
    2. Create a new access key, which includes a new secret access key.
        - To create a new secret access key for your root account, use the [security credentials](https://console.aws.amazon.com/iam/home?#security_credential) page. Expand the Access Keys section, and then click Create New Root Key.
        - To create a new secret access key for an IAM user, open the [IAM console](https://console.aws.amazon.com/iam/home?region=us-east-1#home). Click Users in the Details pane, click the appropriate IAM user, and then click Create Access Key on the Security Credentials tab.
    3. Download the newly created credentials, when prompted to do so in the key creation wizard.

Let's get started with a simple Ballerina program to integrate with Amazon S3.  

### Implementation
The following diagram illustrates all the required functionality of the Amazon S3 Service that you are going to build.

![Amazon S3 Guide Implementation](resources/s3_connector_guide_implementation.svg "Amazon S3 Guide Implementation")

#### Creating the module structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although the 
language allows you to have any module structure, you can use the following simple module structure for this project.

```
working_with_amazons3_client_project
  └── src 
       └── working_with_amazons3_client_module
              └── working_with_amazons3_client.bal
  └── ballerina.conf
```
To create a new project you can use the ballerina new command as follows.
```
$ ballerina new working_with_amazons3_client_project
```
<b>NOTE : </b>Ballerina project cannot reside in another ballerina project. If you run ballerina new inside a ballerina 
project directory or in a sub-path of a ballerina project it will give an error.

Navigate to  `working_with_amazons3_client_project` directory and create the module `working_with_amazons3_client_module` 
using following command.

```
$ ballerina add working_with_amazons3_client_module
```

In the working_with_amazons3_client-module directory where you have your sample, create a `ballerina.conf` file and add the 
details you obtained above within the quotes.

```
ACCESS_KEY_ID = ""
SECRET_ACCESS_KEY = ""
REGION = ""
TRUST_STORE_PATH=""
TRUST_STORE_PASSWORD=""
```
Now that you have created the project structure, the next step is to develop the service.

#### Developing the service

The following code is the completed sample which exposes the following services:
- createBucket: Creates a new bucket on Amazon S3 instance with the provided name.
- createObject: Creates a new object on an existing Amazon S3 bucket.
- getObject: Retrieves an object from an Amazon S3 bucket.
- deleteObject: Deletes an existing object from an Amazon S3 bucket.
- deleteBucket: Deletes specified bucket from Amazon S3 instance.

<!-- INCLUDE_CODE: working_with_amazons3_client.bal -->

### Deployment

#### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first as follows.

**Building**

Navigate to `working_with_amazons3_client_project` and execute the following command.
```bash
$ ballerina build working_with_amazons3_client_module
```

### Testing

- Navigate to `working_with_amazons3_client_project`, and execute the following command to start the service:

```bash
$ ballerina run src/working_with_amazons3_client_module/working_with_amazons3_client.bal
```

#### Test createBucket service
- Invoke the following curl request to create a new bucket.
```
curl -v -X POST http://localhost:9090/amazons3/firstbalbucket
```
You see the response as follows:
```
firstbalbucket created on Amazon S3.
```

#### Test list Bucket service
- Invoke the following curl request to list buckets.
```
curl -X GET http://localhost:9090/amazons3
```

#### Test createObject service
##### (I) JSON Content
Create a file called `content.json` with following JSON content:
```json
{
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "doctor": "thomas collins",
    "hospital": "grand oak community hospital",
    "cardNo": "7844481124110331",
    "appointment_date": "2025-04-02"
}
```
- Invoke the following curl request to create a new object in the newly created bucket.
```
curl -v -X POST --data @content.json http://localhost:9090/amazons3/firstbalbucket/firstObject.json --header "Content-Type:application/json"
```
You see the response as follows:
```
firstObject.json created on Amazon S3 bucket : firstbalbucket.
```

##### (II) Binary Content
Let's upload an image (sample.jpg) to the s3 bucket we created above. 
- Invoke the following curl request to create a new object in the newly created bucket.
```
curl -v -X POST http://localhost:9090/amazons3/firstbalbucket/image.jpg -H 'Content-Type: image/jpg' -T sample.jpg
```
You see the response as follows:
```
image.jpg created on Amazon S3 bucket : firstbalbucket.
```

#### Test list Objects Service
- Invoke the following curl request to list objects in a bucket.
```
curl -X GET http://localhost:9090/amazons3/firstbalbucket
```

#### Test getObject service
##### (I) JSON Content
- Set the `responseContentType` as `application/json` to retrieve a JSON object and invoke the following curl request to get the newly created object.
```
curl -v -X GET http://localhost:9090/amazons3/firstbalbucket/firstObject.json?responseContentType=application/json
```
You see the response as follows:
```json
{
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "doctor": "thomas collins",
    "hospital": "grand oak community hospital",
    "cardNo": "7844481124110331",
    "appointment_date": "2025-04-02"
}
```

##### (II) Binary Content
- Set the `responseContentType` as image/jpg and use following URL to open newly created image on browser.
```
http://localhost:9090/amazons3/firstbalbucket/image.jpg?responseContentType=image/jpg
```

- Set the `responseContentType` as application/octet-stream and use the following URL to download newly created image.
```
http://localhost:9090/amazons3/firstbalbucket/image.jpg?responseContentType=application/octet-stream
```

#### Test deleteObject service
- Invoke the following curl request to delete the above object.
```
curl -v -X DELETE http://localhost:9090/amazons3/firstbalbucket/firstObject.json
```
You see the response as follows:
```
firstObject.json deleted on Amazon S3 bucket : firstbalbucket.
```

#### Test deleteBucket service
- Invoke the following curl request to delete the above bucket.
```
curl -v -X DELETE http://localhost:9090/amazons3/firstbalbucket
```
You see the response as follows:
```
firstbalbucket deleted from Amazon S3
```
