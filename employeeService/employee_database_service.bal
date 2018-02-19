package employeeService;

import ballerina.config;
import ballerina.log;
import ballerina.net.http;
import employeeService.util.db as databaseUtil;


service<http> records {

    string dbHost = config:getGlobalValue("DATABASE_HOST");
    string dbPort = config:getGlobalValue("DATABASE_PORT");
    string userName = config:getGlobalValue("DATABASE_USERNAME");
    string password = config:getGlobalValue("DATABASE_PASSWORD");
    string dbName = config:getGlobalValue("DATABASE_NAME");

    boolean isInitialized = databaseUtil:initializeDatabase(dbHost, dbPort, userName, password, dbName);

    @http:resourceConfig {
        methods:["POST"],
        path:"/employee/"
    }
    resource addEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        // Convert the json payload to string values
        var name, nameError = (string)requestPayload.Name;
        var age, ageError = (string)requestPayload.Age;
        var ssn, ssnError = (string)requestPayload.SSN;
        var employeeId, empIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Check query parameter errors and send bad request response if errors present
        if (nameError != null || ageError != null || ssnError != null || empIdError != null) {
            response.setStringPayload("Error : Please check the input parameters ");
            response.statusCode = 400;
            _ = httpConnection.respond(response);
            return;
        }

        // Invoke insertData function to store data in the MySQL database
        json updateStatus = databaseUtil:insertData(name, age, ssn, employeeId);
        log:printInfo("New employee added to database: employeeID = " + employeeId);

        // Send the response back to the client with the status of the database operation
        json respJson = {"Name":name, "Age":age, "SSN":ssn, "EmployeeID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/employee/"
    }
    resource retrieveEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        map queryParams = request.getQueryParams();
        var employeeId, employeeIdError = (string)queryParams.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Check query parameter errors and sending bad request response if errors present
        if (employeeIdError != null) {
            response.setStringPayload("Error : Please check the input parameters ");
            response.statusCode = 400;
            _ = httpConnection.respond(response);
            return;
        }

        // Invoke retrieveById function to retrieve data from MySQL database
        json employeeData = databaseUtil:retrieveById(employeeId);

        // Send the response back to the client with the employee data
        response.setJsonPayload(employeeData);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["PUT"],
        path:"/employee/"
    }
    resource updateEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        // Convert the json payload to string values
        var name, nameError = (string)requestPayload.Name;
        var age, ageError = (string)requestPayload.Age;
        var ssn, ssnError = (string)requestPayload.SSN;
        var employeeId, employeeIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Check query parameter errors and sending bad request response if errors present
        if (nameError != null || ageError != null || ssnError != null || employeeIdError != null) {
            response.setStringPayload("Error : Please check the input parameters ");
            response.statusCode = 400;
            _ = httpConnection.respond(response);
            return;
        }

        // Invoke updateData function to update data in MySQL database
        json updateStatus = databaseUtil:updateData(name, age, ssn, employeeId);
        log:printInfo("Employee details updated in database: EmployeeID = " + employeeId);

        // Send the response back to the client with database update status
        json respJson = {"Name":name, "Age":age, "SSN":ssn, "EmployeeID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }

    @http:resourceConfig {
        methods:["DELETE"],
        path:"/employee/"
    }
    resource deleteEmployeeResource (http:Connection httpConnection, http:InRequest request) {
        // Extract the data from the request payload
        json requestPayload = request.getJsonPayload();
        var employeeId, employeeIdError = (string)requestPayload.EmployeeID;

        // Initialize an empty http response message
        http:OutResponse response = {};

        // Check query parameter errors and sending bad request response if errors present
        if (employeeIdError != null) {
            response.setStringPayload("Error : Please check the input parameters ");
            response.statusCode = 400;
            _ = httpConnection.respond(response);
            return;
        }

        // Invoke deleteData function to delete data from MySQL database
        json updateStatus = databaseUtil:deleteData(employeeId);
        log:printInfo("Employee deleted from database: EmployeeID = " + employeeId);

        // Send the response back to the client with status of SQL delete operation
        json respJson = {"Employee ID":employeeId, "Status":updateStatus};
        response.setJsonPayload(respJson);
        _ = httpConnection.respond(response);
    }
}