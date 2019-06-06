# Service Chaining

In this example, we're going to integrate many service calls and expose as a single service. This is commonly referred to as Service Chaining, where several services are integrated based on some business logic and exposed as a single, aggregated service.

## Backend  

We will use the same hospital service as the backend for this example. The hospital service exposes multiple services i.e making an appointment reservation, viewing appointment details, viewing the doctors' details, etc. We will combine two of such services, making an appointment reservation and settling the payment for the reservation, and expose them as a single service in ballerina.  

## Developement

In this example, we will expose a service in ballerina named 'makeReservation'. A client will call this service with the request payload.  This service will first call the reservation service of the backend and obtain a response. Using that response, it will call the payment settlement service of the backend and obtain a response. Finally it will send the response back to the client. 

Following is the service definition.

```ballerina
resource function makeReservation(http:Caller caller, http:Request request, string category) {
        var requestPayload = request.getJsonPayload();
        if (requestPayload is json) {
            // tranform the request payload to the format expected by the backend end service
            json reservationPayload = {
                "patient": {
                    "name": requestPayload.name,
                    "dob": requestPayload.dob,
                    "ssn": requestPayload.ssn,
                    "address": requestPayload.address,
                    "phone": requestPayload.phone,
                    "email": requestPayload.email
                },
                "doctor": requestPayload.doctor,
                "hospital": requestPayload.hospital,
                "appointment_date": requestPayload.appointment_date
            };
            // call appointment creation
            http:Response reservationResponse = createAppointment(caller, untaint reservationPayload, category);

            json | error responsePayload = reservationResponse.getJsonPayload();
            if (responsePayload is json) {
                // check if the json payload is actually an appointment confirmation response
                if (responsePayload.appointmentNumber is ()) {
                    respondToClient(caller, createErrorResponse(500, untaint responsePayload.toString()));
                    return;
                }
                // call payment settlement
                http:Response paymentResponse = doPayment(untaint responsePayload);
                // send the response back to the client
                respondToClient(caller, paymentResponse);
            } else {
                respondToClient(caller, createErrorResponse(500, "Backend did not respond with json"));
            }
        } else {
            respondToClient(caller, createErrorResponse(400, "Not a valid Json payload"));
        }
    }
```
Initially we check if the request payload is of json. If so, we transform it to the format expected by the backend. Then we call the function which gives the request for appointment creation. We then get the first response and check if it is json. Then we check if it is an actual appointment confirmation response. If not, we simply throw an error. If so, we call the function that gives the payment settlement request. Finally we get its response and send it back to the client. We throw errors if the backend response is not json or if the original request payload is also not json.

## Invoking the Service

Let's start the service by navigating to the folder where the reserve_appointment_service.bal file is and issue the following command.

```
ballerina run reserve_appointment_service.bal
```
The 'makeReservation' service will start on port 9091. Now we can send an HTTP request to this service. 

Lets create a file name request.json with following content.

```json
{
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-523",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "doctor": "thomas collins",
    "hospital": "grand oak community hospital",
    "cardNo": "7844481124110331",
    "appointment_date": "2025-04-02"
}
```
And issue a curl request as follows. 

```
curl -v http://localhost:9091/healthcare/categories/surgery/reserve -H 'Content-Type:application/json' --data @request.json '
```

Following will be a sample response of a succesful appointment reservation.

```json
{
    "appointmentNo": 1,
    "doctorName": "thomas collins",
    "patient": "John Doe",
    "actualFee": 7000.0,
    "discount": 20,
    "discounted": 5600.0,
    "paymentID": "b7981676-c1ca-4380-bc31-1725eb121d1a",
    "status": "Settled"
}
```
