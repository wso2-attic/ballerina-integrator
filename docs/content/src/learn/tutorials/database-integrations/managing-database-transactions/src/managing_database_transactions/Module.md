Template for Database Transactions using Ballerina

# Database Transactions using Ballerina 

This is a template for [Managing Database Transactions tutorial](https://ei.docs.wso2.com/en/7.0.0/ballerina-integrator/learn/tutorials/database-integrations/managing-database-transactions/1/). Please refer to it for more details on what you are going to build here. This template provides a starting point for your scenario. 


## Using the Template

Run the following command to pull the `managing_database_transactions` template from Ballerina Central.

```
$ ballerina pull wso2/managing_database_transactions
```

Create a new project.

```bash
$ ballerina new managing_database_transactions
```

Now navigate into the above module directory you created and run the following command to apply the predefined template you pulled earlier.

```bash
$ ballerina add -t wso2/managing_database_transactions managing_database_transactions
```

This automatically creates managing_database_transactions service for you inside the `src` directory of your project.  

## Testing

Run the SQL script `database_initializer.sql` provided in the resources folder, to initialize the database and to create the required table.
```bash
$ mysql -u username -p <database_initializer.sql
```
Add database configurations to the `ballerina.conf` file.
   - `ballerina.conf` file can be used to provide external configurations to Ballerina programs. Since this guide needs MySQL database integration, a Ballerina configuration file is used to provide the database connection properties to our Ballerina program.
   This configuration file has the following fields. Change these configurations with your connection properties accordingly.
   
```
DATABASE_URL = "jdbc:mysql://127.0.0.1:3306/bankDB"
DATABASE_USERNAME = "root"
DATABASE_PASSWORD = "root"
```

Let’s build the module. Navigate to the project root directory and execute the following command.

```bash
$ ballerina build --experimental managing_database_transactions 
```

This creates the executables. Now run the `managing_database_transactions.jar` file created in the above step.Path to the `ballerina.conf` could be provided using the `--b7a.config.file` option.

```bash
$ java -jar target/bin/managing_database_transactions.jar --b7a.config.file=path/to/ballerina.conf/file
```
