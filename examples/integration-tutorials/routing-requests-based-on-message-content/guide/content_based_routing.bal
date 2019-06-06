import ballerina/http;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/healthcare"
}
service contentBasedRouting on new http:Listener(9080) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function CBRResource(http:Caller outboundEP, http:Request req, string category) {
        var jsonMsg = req.getJsonPayload();
        if (jsonMsg is json) {
            string hospitalDesc = jsonMsg["hospital"].toString();
            string doctorName = jsonMsg["doctor"].toString();
            string hospitalName = "";
            http:Client locationEP = new("http://localhost:9090");
            http:Response|error clientResponse;
            if (hospitalDesc != "") {
                match hospitalDesc {
                    "grand oak community hospital" => hospitalName = "grandoaks";
                    "clemency medical center" => hospitalName = "clemency";
                    "pine valley community hospital" => hospitalName = "pinevalley";
                }
                string sendPath = "/" + hospitalName + "/categories/" + category + "/reserve";
                clientResponse = locationEP -> post(untaint sendPath, untaint jsonMsg);
            } else {
                return;
            }
            if (clientResponse is http:Response) {
                var result = outboundEP->respond(clientResponse);
                if (result is error) {
                    log:printError("Error at the backend", err = result);
                }
            } else {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(<string>clientResponse.detail().message);
                var result = outboundEP->respond(res);
                if (result is error) {
                   log:printError("Backend not properly responds", err = result);
                }
            }
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(untaint <string>jsonMsg.detail().message);
            var result = outboundEP->respond(res);
            if (result is error) {
               log:printError("Request is not JSON", err = result);
            }
        }
    }
}
