import ballerina/http;
import ballerina/log;

http:Client hospitalEP = new("http://localhost:9090");

const GRAND_OSK_EP_PATH = "/grandoaks/categories/";
const CLEMENCY_EP_PATH = "/clemency/categories/";
const PINE_VALLEY_EP_PATH = "/pinevalley/categories/";
const string ERROR_CODE = "Sample Error";

@http:ServiceConfig {
    basePath: "/healthcare"
}
service healthcareService on new http:Listener(9091) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/categories/{category}/reserve"
    }
    resource function makeReservation(http:Caller caller, http:Request request, string category) {
        //Extract payload from the request.
        var requestPayload = request.getJsonPayload();
        json modifiedPayload = {};
        string requestPath = "";
        http:Response|error backendResponse = new();

        if (requestPayload is json) {
            //Get hospital name.
            json hospitalName = requestPayload.hospital;
            //Transform the payload into the format which is required by the backend service.
            modifiedPayload = {
                "patient": {
                    "name": requestPayload.name,
                    "dob": requestPayload.dob,
                    "ssn": requestPayload.ssn,
                    "address": requestPayload.address,
                    "phone": requestPayload.phone,
                    "email": requestPayload.email,
                    "cardNo": requestPayload.cardNo
                },
                "doctor": requestPayload.doctor,
                "hospital": hospitalName,
                "appointment_date": requestPayload.appointment_date
            };
            log:printInfo(modifiedPayload.toString());
            http:Request backendRequest = new();
            backendRequest.setPayload(untaint modifiedPayload);

            match hospitalName {
                "grand oak community hospital" => {
                    backendResponse = hospitalEP->post(untaint string `${GRAND_OSK_EP_PATH}/${category}/reserve`,
                                                backendRequest);  
                }
                "clemency medical center" => {
                    backendResponse = hospitalEP->post(untaint string `${CLEMENCY_EP_PATH}/${category}/reserve`, 
                                                backendRequest); 
                }
                "pine valley community hospital" => {
                    backendResponse = hospitalEP->post(untaint string `${PINE_VALLEY_EP_PATH}/${category}/reserve`, 
                                                backendRequest);
                }          
                _ => {
                    error err = error(ERROR_CODE, { message: "Unknown hospital name."});
                    backendResponse = err;
                } 
            } 
        } else {
            error err = error(ERROR_CODE, { message: "Invalid json request payload."});
            backendResponse = err;
        }
        
        if (backendResponse is http:Response) {
            respondAndHandleError(caller, untaint backendResponse, "Error in responding to client!");
        } else {
            createAndSendErrorResponse(caller, untaint backendResponse, "Error in sending request to backend service.");
        }
    }
}

function createAndSendErrorResponse(http:Caller caller, error sourceError, string respondErrorMsg) {
    http:Response response = new;
    response.statusCode = 500;
    response.setPayload(<string> sourceError.detail().message);
    respondAndHandleError(caller, response, respondErrorMsg);
}

function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}
