import ballerina/http;
import ballerina/mysql;
import ballerina/test;

boolean serviceStarted;

function startService() {
    serviceStarted = test:startServices("message_transformation");
}

@test:Config {
    before: "startService",
    after: "stopService"
}

function message_transformation_check() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };
    // Chck whether the server is started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");
    json payload = {"id" : 105, "name" : "saneth", "city" : "Colombo 03", "gender" : "male"};
    json response1 = {"id":105,"city":"Colombo 03","gender":"male","fname":"saneth",
        "results":{"Com_Maths":"A","Physics":"B","Chemistry":"C"}};

    http:Request req = new;
    req.setJsonPayload(payload);
    // Send a GET request to the specified endpoint
    var response = httpEndpoint->post("/contentfilter", req);
    match response {
        http:Response resp => {
            var jsonRes = check resp.getJsonPayload();
            test:assertEquals(jsonRes, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function stopService() {
    test:stopServices("message_transformation");
}
