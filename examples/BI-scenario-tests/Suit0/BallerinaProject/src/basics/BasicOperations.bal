import ballerina/config;
import ballerina/http;
import ballerina/log;
import wso2/ftp;
import ballerina/io;

const string remoteLocationJson = "/home/ftp-user/in/account.json";
const string remoteLocationXML = "/home/ftp-user/in/client.xml";
const string remoteLocationText = "/home/ftp-user/in/student.txt";


ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("ftp.host"),
    port: config:getAsInt("ftp.port"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("ftp.username"),
            password: config:getAsString("ftp.password")
        }
    }
};
ftp:Client ftp = new (ftpConfig);

@http:ServiceConfig {
    basePath: "company"
}

service company on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addJsonFile"
    }

    resource function addJsonFile(http:Caller caller, http:Request request) returns error? {
        http:Response response = new ();
        json jsonPayload = check request.getJsonPayload();
        var ftpResult = ftp->put(remoteLocationJson, jsonPayload);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred uploading file to FTP.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: "Employee records uploaded successfully."});
        }
        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addTextFile"
    }

    resource function addTextFile(http:Caller caller, http:Request request) returns error? {
        http:Response response = new ();
        json textPayload = check request.getTextPayload();
        var ftpResult = ftp->put(remoteLocationText, textPayload);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred uploading file to FTP.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: "Employee records uploaded successfully."});
        }
        var httpResult = caller->respond(response);
    }

        @http:ResourceConfig {
        methods: ["POST"],
        path: "/addXMLFile"
    }

    resource function addXMLFile(http:Caller caller, http:Request request) returns error? {
        http:Response response = new ();
        xml xmlPayload = check request.getXmlPayload();
        var ftpResult = ftp->put(remoteLocationXML, xmlPayload);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred uploading file to FTP.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: "Employee records uploaded successfully."});
        }
        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/readFile/{fileName}"
    }
        resource function readFile(http:Caller caller, http:Request request, string fileName) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->get("/home/ftp-user/in/" + fileName);
        if (ftpResult is io:ReadableByteChannel) {
            io:ReadableCharacterChannel? characters = new io:ReadableCharacterChannel(ftpResult, "utf-8");
            if (characters is io:ReadableCharacterChannel) {
                var output = characters.read(1000);
                if (output is json | xml | string | byte) {
                    response.setPayload(<@untained>(output));
                } else {
                    response.setJsonPayload(<@untained>({
                        Message: "Error occured in retrieving content",
                        Reason: output.reason()
                    }));
                    log:printError("Error occured in retrieving content", output);
                }
                var closeResult = characters.close();
                if (closeResult is error) {
                    log:printError("Error occurred while closing the channel", closeResult);
                }
            }
        } else {
            response.setJsonPayload({Message: "Error occured in retrieving content", Reason: ftpResult.reason()});
        }
        var httpResult = caller->respond(response);

    }

     @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/deleteFile/{fileName}"
    }

    resource function deleteFile(http:Caller caller, http:Request request, string fileName) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->delete("/home/ftp-user/in/" +fileName);

        if (ftpResult is error) {
            response.setJsonPayload({Message: "Error occurred while deleting the file.", Reason: ftpResult.reason()});
            log:printError("Error occurred while deleting a file", ftpResult);
        }
        else {
            response.setJsonPayload({Message: "Employee records deleted successfully."});
            log:printInfo("Successfully deleted file");
        }

        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        path: "/createFolder/{folderName}"
    }

    resource function createFolder(http:Caller caller, http:Request request, string folderName) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->mkdir("/home/in/" + folderName);

        if (ftpResult is error) {
            response.setJsonPayload({Message: "Error occurred creating folder.", Resason: ftpResult.reason()});
            log:printError("Error occurred while creating a folder", ftpResult);
        }
        else {
            response.setJsonPayload({Message: "The folder is created successfully."});
            log:printInfo("The folder is created successfully.");
        }

        var httpResult = caller->respond(response);

    }

     @http:ResourceConfig {
        path: "/removeFolder/{folderName}"
    }

    resource function removeFolder(http:Caller caller, http:Request request, string folderName) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->rmdir("/home/in/" + folderName);

        if (ftpResult is error) {
            response.setJsonPayload({Message: "Error occurred deleting the folder.", Reason: ftpResult.reason()});
            log:printError("Error occurred while deleting the folder", ftpResult);
        }
        else {
            response.setJsonPayload({Message: "The folder is deleted successfully."});
            log:printInfo("The folder is deleted successfully.");
        }

        var httpResult = caller->respond(response);

    }

     @http:ResourceConfig {
        path: "/renameFile/{existingFileName}/{newFileName}"
    }

    resource function renameFile(http:Caller caller, http:Request request, string existingFileName, string newFileName) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->rename("/home/ftp-user/in/"+existingFileName, "/home/ftp-user/in/"+newFileName);

        if (ftpResult is error) {
            response.setJsonPayload({Message: "Error occurred renaming the file.", Reason: ftpResult.reason()});
            log:printError("Error occurred while renaming the file", ftpResult);
        }
        else {
            response.setJsonPayload({Message: "The file is renamed successfully."});
            log:printInfo("The file is renamed successfully.");
        }
        var httpResult = caller->respond(response);
    }

     @http:ResourceConfig {
        path: "/retreiveFileSize/{fileName}"
    }

    resource function retreiveFileSize(http:Caller caller, http:Request request, string fileName) returns error? {
        http:Response response = new ();
        var ftpResponse = ftp->size("/home/ftp-user/in/"+ fileName);
        if (ftpResponse is int) {
            response.setJsonPayload({FileSize: ftpResponse});
        } else {
            response.setJsonPayload({Message: "Error occured in retrieving size", Reason: ftpResponse.reason()});
            log:printError("Error occured in retrieving size", ftpResponse);
        }
        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        path: "/listFiles"
    }

    resource function listFiles(http:Caller caller, http:Request request)returns error?{
        http:Response response = new ();
        var ftpResult = ftp->list("/home/ftp-user/in");

        if (ftpResult is error) {
            response.setJsonPayload({Message: "Error occurred while listing the files", Reason: ftpResult.reason()});
            log:printError("Error occurred while listing the files", ftpResult);
        }
        else
        {

            response.setJsonPayload({Files: ftpResult.toString()});
        }
        var httpResult = caller->respond(response);

    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addFiles/{customizedLocation}"
    }

    resource function addFiles(http:Caller caller, http:Request request, string customizedLocation) returns error? {
        http:Response response = new ();
        string textPayload = check request.getTextPayload();
        var ftpResult = ftp->put(customizedLocation, textPayload);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred uploading file to FTP.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: "File uploaded successfully."});
        }
        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        path: "/verifyDirectory/{folder}"
    }
    resource function verifyDirectory(http:Caller caller, http:Request request, string folder) returns error? {
        http:Response response = new ();
        var ftpResult = ftp->isDirectory(folder);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred while retreiving the boolean value.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: ftpResult});
        }
        var httpResult = caller->respond(response);
    }

    @http:ResourceConfig {
        path: "/appendFile/{fileName}"
    }
    resource function appendFile(http:Caller caller, http:Request request, string fileName) returns error? {
        http:Response response = new ();
        string textPayload = check request.getTextPayload();
        var ftpResult = ftp->append(fileName,textPayload);

        if (ftpResult is error) {
            log:printError("Error", ftpResult);
            response.setJsonPayload({Message: "Error occurred while appending the file.", Resason: ftpResult.reason()});
        } else {
            response.setJsonPayload({Message: "File appended successfully"});
        }
        var httpResult = caller->respond(response);
    }

}
