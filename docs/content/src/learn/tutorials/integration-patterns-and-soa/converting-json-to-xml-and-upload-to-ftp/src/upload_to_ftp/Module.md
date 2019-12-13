Template to convert JSON to XML and upload to FTP

# REST to SOAP 

This is a template for the [JSON to XML and upload to FTP tutorial](https://ei.docs.wso2.com/en/latest/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/converting-json-to-xml-and-upload-to-ftp/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `upload_to_ftp` template from Ballerina Central.

```
$ ballerina pull wso2/upload_to_ftp
```

Create a new project.

```bash
$ ballerina new converting-json-to-xml-and-upload-to-ftp
```

Now navigate into the above project directory you created and run the following command to apply the predefined template 
you pulled earlier.

```bash
$ ballerina add upload_to_ftp -t wso2/upload_to_ftp
```

This automatically creates upload_to_ftp service for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build upload_to_ftp 
```

This creates the executables. Now run the `upload_to_ftp.jar` file created in the above step.

```bash
$ java -jar target/bin/upload_to_ftp.jar
```

Now we can see that the service has started on port 8080. 

Create an employees.json file with the below payload.
```json
{
   "employees":{
      "employee":[
         {
            "firstname":"Peter",
            "lastname":"Pan",
            "Age":25,
            "addresses":{
               "address":[
                  {
                     "street":"123 Town hall",
                     "city":"Colombo"
                  },
                  {
                     "street":"987 Palm Grove",
                     "city":"Colombo"
                  }
               ]
            }
         },
         {
            "firstname":"Alex",
            "lastname":"Stuart",
            "Age":30,
            "addresses":{
               "address":[
                  {
                     "street":"456 Flower Road",
                     "city":"Galle"
                  },
                  {
                     "street":"654 Sea Street",
                     "city":"Galle"
                  }
               ]
            }
         }
      ]
   }
}
```

Let’s access this service by executing the following curl command.

```bash
$ curl -H "application/json" -d @employees.json http://localhost:8080/company/employees
```
