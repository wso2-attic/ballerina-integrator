Template for JSON to XML and upload to FTP

# REST to SOAP 

This is a template for the [JSON to XML and upload to FTP tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/integration-patterns-and-soa/converting-json-to-xml-and-upload-to-ftp/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `uploadtoftp` template from Ballerina Central.

```
$ ballerina pull wso2/uploadtoftp
```

Create a new project.

```bash
$ ballerina new converting-json-to-xml-and-upload-to-ftp
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/uploadtoftp uploadtoftp
```

This automatically creates restful_service for you inside the `src` directory of your project.  

## Testing

First let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build uploadtoftp 
```

This creates the executables. Now run the `uploadtoftp.jar` file created in the above step.

```bash
$ java -jar target/bin/uploadtoftp.jar
```

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

Now we can see that the service has started on port 8080. Let’s access this service by executing the following curl command.

```bash
$ curl -H "application/json" -d @employees.json http://localhost:8080/company/employees
```
