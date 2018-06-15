import ballerina/test;
import ballerina/http;
import ballerina/io;

@test:BeforeSuite 
function setupService () {
    _ = test:startServices("message-filtering");
}

endpoint http:Client clientEP {
    url:"http://localhost:9090/filterService"
};

@test:Config
function testResourceFilterMarks () {

    http:Request req = new;
    json payload = {"students":[{"name":"Saman","subject":"Maths","marks":80},{"name":"Sugath","subject":"Maths","marks":34}]};
    req.setJsonPayload(payload);
    http:Response res = check clientEP -> post("/filterMarks", request = req);
    
    test:assertEquals(res.statusCode, 200, msg = "filterMarks resource did not respond with expected response code!");

    json resPayload = check res.getJsonPayload();
    json passStdInfo = resPayload.students[0];

    test:assertEquals(passStdInfo.toString(), "{\"name\":\"Saman\",\"mark\":80}", msg = "Response mismatch!");

}


