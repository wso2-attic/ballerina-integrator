import ballerina/test;
import ballerina/http;

json sampleRequest = {
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
};

http:Client clientEP = new("http://localhost:9091/healthcare");

@test:Config
function testTransformation() {
    http:Request req = new;
    req.setJsonPayload(sampleRequest);
    var response = clientEP->post("/categories/surgery/reserve", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, 
                msg = "Message Transformation -> Service did not respond with 200 OK!");
        json expected = false;
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.confirmed, expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Payload from reservation service is invalid");
        }
    } else {
        test:assertFail(msg = "Response from reservation service is invalid");
    }
}
