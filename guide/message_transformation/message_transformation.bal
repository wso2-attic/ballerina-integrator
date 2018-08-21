import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/mysql;
//import ballerinax/kubernetes;
//import ballerinax/docker;

//Connect the student details table
endpoint mysql:Client studentDetailsDB {
    host: "localhost",
    port: 3306,
    name: "StudentDetailsDB",
    username: "root",
    password: "wso2123",
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};

//Connect the student's results details table
endpoint mysql:Client studentResultsDB {
    host: "localhost",
    port: 3306,
    name: "StudentResultsDB",
    username: "root",
    password: "wso2123",
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"message_transformation",
//    path:"/"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"contentfilter"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"validate"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"enricher"
//}
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"backend"
//}
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/message_transformation_service:v1.0",
//    name:"ballerina-guides-message-transformation-service",
//    baseImage:"ballerina/ballerina-platform:0.981.0",
//    copyFiles:[{target:"/ballerina/runtime/bre/lib",
//        source:"<mysql-connector-path>"}]
//}

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"message_transformation",
//    tag:"v1.0",
//    baseImage:"ballerina/ballerina-platform:0.980.0"
//}
//@docker:CopyFiles {
//    files:[{source:"<mysql-connector-path>",
//        target:"/ballerina/runtime/bre/lib"}]
//}
//
//@docker:Expose {}
//Define end points lister http ports for the service endpoints
endpoint http:Listener contentfilterEP {
    port: 9090
};
endpoint http:Listener claimvalidateEP {
    port: 9094
};
endpoint http:Listener contentenricherEP {
    port: 9092
};
endpoint http:Listener backendEP {
    port: 9093
};
//Define endpoints for services
endpoint http:Client validatorEP {
    url: "http://localhost:9094/validate"
};
endpoint http:Client enricherEP {
    url: "http://localhost:9092/enricher"
};
endpoint http:Client clientEP {
    url: "http://localhost:9093/backend"
};

//Define the global variables
public json payload1;
public json payload2;

//Service for the content filter pattern
service<http:Service> contentfilter bind contentfilterEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    contentfilter(endpoint caller, http:Request req) {
        http:Request filteredReq = req;
        var jsonMsg = req.getJsonPayload();
        match jsonMsg {
            json msg => {
                //Create the StudentDetails table in the DB
                var ret = studentDetailsDB->update(
                     "CREATE TABLE StudentDetails (id INT, name VARCHAR(255), city VARCHAR(255), gender VARCHAR(255))"
                );
                handleUpdate(ret, "Create the table");
                http:Response res = new;
                if (!checkForValidData(msg, res)) {
                    caller->respond(res) but {
                        error e =>
                        log:printError("Error sending response", err = e)
                    };
                } else {
                    //Assign user input values to variables
                    int IdValue = check <int>msg["id"];
                    string nameString = check <string>msg["name"];
                    string cityString = check <string>msg["city"];
                    string genderString = check <string>msg["gender"];
                    //Add values to the student details table
                    ret = studentDetailsDB->update(
                             "INSERT INTO StudentDetails(id, name, city, gender) values (?, ?, ?, ?)", IdValue,
                             nameString, cityString, genderString);
                    handleUpdate(ret, "Add details to the table");
                    json iddetails = { id: IdValue };
                    //Set filtered payload to the request
                    filteredReq.setJsonPayload(untaint iddetails);
                    //Forward request to the nesxt ID validating service
                    var clientResponse = validatorEP->forward("/", filteredReq);
                    match clientResponse {
                        http:Response response => {
                            caller->respond(response) but {
                                error e =>
                                log:printError("Error sending response", err = e)
                            };
                        }
                        error err => {
                            http:Response response = new;
                            response.statusCode = 500;
                            response.setPayload(err.message);
                            caller->respond(response) but {
                                error e =>
                                log:printError("Error sending response", err = e)
                            };
                        }
                    }
                }
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.message);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error while content reading", err = e)
                };
            }
        }

    }
}

//The student ID validate service
service<http:Service> validate bind claimvalidateEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    validate(endpoint caller, http:Request filteredReq) {
        http:Request validatededReq = filteredReq;
        //Get the payload in the request (Student ID)
        var jsonMsg = filteredReq.getJsonPayload();
        match jsonMsg {
            json msg => {
                int Idvalue = check <int>msg["id"];
                //validate the student's ID
                //In this example student's ID should be in between 100 to 110
                if ((100 <= Idvalue) && (Idvalue <= 110))  {
                    //Print the validity
                    io:println("The  Student ID is succussfully validated");
                    //Forward the request to the enricher service
                    var clientResponse = enricherEP->forward("/", validatededReq);
                    match clientResponse {
                        http:Response res => {
                            caller->respond(res) but {
                                error e =>
                                log:printError("Error sending response", err = e)
                            };
                        }
                        error err => {
                            http:Response res = new;
                            res.statusCode = 500;
                            res.setPayload(untaint err.message);
                            caller->respond(res) but {
                                error e =>
                                log:printError("Error sending response", err = e)
                            };
                        }
                    }
                }
                else {
                    error err = { message: "Student ID: " + Idvalue + " is not found" };
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload(untaint err.message);
                    caller->respond(res) but {
                        error e =>
                        log:printError("Error sending response", err = e)
                    };
                }
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.message);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error while content reading", err = e)
                };
            }
        }

    }
}

//The content enricher service
service<http:Service> enricher bind contentenricherEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    enricher(endpoint caller, http:Request validatedReq) {
        http:Request enrichedReq = validatedReq;
        var jsonMsg = validatedReq.getJsonPayload();
        match jsonMsg {
            json msg => {
                //Get the student's ID value
                int Idvalue = check <int>msg["id"];
                //Select details from the data table according to the student's ID
                var selectRet = studentDetailsDB->select("SELECT * FROM StudentDetails", ());
                table dt;
                match selectRet {
                    table tableReturned => dt = tableReturned;
                    error e => io:println("Select data from StudentDetails table failed: "
                            + e.message);
                }
                //Convert the details to a jason file
                io:println("\nConvert the table into json");
                var jsonConversionRet = <json>dt;
                match jsonConversionRet {
                    json jsonRes => {
                        //Set student's details to the global variable
                        payload1 = untaint jsonRes;
                        io:println(payload1);
                    }
                    error e => io:println("Error in student table to json conversion");
                }
                //Drop the student details table
                var ret = studentDetailsDB->update("DROP TABLE StudentDetails");
                handleUpdate(ret, "Drop table student");
                //Select student's results from the student results data table, according to the student's ID
                var selectRet1 = studentResultsDB->select(
                            "select Com_Maths,Physics,Chemistry from StudentResults where ID = ?", (), Idvalue);
                table dt1;
                match selectRet1 {
                    table tableReturned => dt1 = tableReturned;
                    error e => io:println("Select data from StudentResults table failed: "
                            + e.message);
                }
                //Convert the details to a jason file
                io:println("\nConvert the table into json");
                var jsonConversionRet1 = <json>dt1;
                match jsonConversionRet1 {
                    json jsonRes1 => {
                        //Set student's result details to the global variable
                        payload2 = untaint jsonRes1;
                    }
                    error e => io:println("Error in StudentDetails table to json conversion");
                }

                //jason to jason conversion to the selected details
                //Define new jason variable
                json pay = payload1[0];
                //Add extra values to the jason payload
                pay.fname = pay.name;
                //remove values from the jason payload
                pay.remove("name");
                //Add results to the same payload
                pay.results = payload2[0];
                //Set enriched payload to the request
                enrichedReq.setJsonPayload(pay);
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.message);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error sending response", err = e)
                };
            }
        }
        //Forward enriched request to the client endpoint
        var clientResponse = clientEP->forward("/", enrichedReq);
        match clientResponse {
            http:Response res => {
                caller->respond(res) but {
                    error e =>
                    log:printError("Error sending response", err = e)
                };
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error sending response", err = e)
                };
            }
        }
    }
}

//Client endpoint service to display the request payload
service<http:Service> backend bind backendEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    backendservice(endpoint caller, http:Request enrichedReq) {
        //Get the requset payload
        var jsonMsg = enrichedReq.getJsonPayload();
        match jsonMsg {
            json msg => {
                //Send payload as response
                http:Response res = new;
                res.setJsonPayload(untaint msg);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error sending response", err = e)
                };
            }
            error err => {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(untaint err.message);
                caller->respond(res) but {
                    error e =>
                    log:printError("Error sending response", err = e)
                };
            }
        }
    }
}

//Function to handle the user input
function checkForValidData(json msg, http:Response res) returns boolean {
    boolean returnError = false;
    error err;
    //Check input through the regular expressions
    if (!(check msg.id.toString().matches("\\d+"))) {
        err = { message: "student ID containts invalid data" };
        returnError = true;
    } else if (!(check msg.name.toString().matches("[a-zA-Z]+"))) {
        err = { message: "student Name containts invalid data" };
        returnError = true;
    } else if (!(check msg.city.toString().matches("^[a-zA-Z]+([\\-\\s]?[a-zA-Z0-9]+)*$"))) {
        err = { message: "student city containts invalid data" };
        returnError = true;
    } else if (!(check msg.gender.toString().matches("[a-zA-Z]+"))) {
        err = { message: "student gender containts invalid data" };
        returnError = true;
    }
    if (returnError) {
        res.statusCode = 400;
        res.setPayload(err.message);
        return false;
    } else {
        return true;
    }
}

//function for the error handling part in extract values from payload to variables
function handleUpdate(int|error returned, string message) {
    match returned {
        int retInt => io:println(message + " status: " + retInt);
        error e => io:println(message + " failed: " + e.message);
    }
}
