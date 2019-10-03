# Service Orchestration

## About

Service orchestration is a common integration scenario where, upon a request from a client, a service calls multiple other services/endpoints. This guide demonstrates a simple service orchestration scenario where a client makes a doctor's appointment and the service invokes the other two services to make a reservation and to do the payment for the reservation fee respectively.

## What you'll build

We will build a service called `doctorAppointment` that accepts a client's request for a doctor’s appointment. The service calls the reservation service with the request payload sent by the client to reserve the appointment, gets the response, checks if the appointment is confirmed, and if confirmed, calls the payment endpoint to settle the fee of the appointment. Finally, if the payment is successful, it will merge both the responses from the appointment service and the payment service and respond back to the client. If the appointment reservation is not successful, it sends back a payload saying the appointment failed.

![service-orchestration](../../../../assets/img/service_orchestration.jpg)

## Prerequisites

- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install the Ballerina IDE plugin for [VS Code](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina)
	
## Implementation

* Create a new Ballerina project named `service-orchestration`.

    ```bash
    $ ballerina new service-orchestration
    ```

* Navigate to the service-orchestration directory.

* Add a new module named `appointment_service` to the project.

    ```bash
    $ ballerina add appointment_service
    ```

* Open the project with VS Code. The project structure will be similar to the following.

    ```shell
    .
    ├── Ballerina.toml
    └── src
        └── appointment_service
            ├── main.bal
            ├── Module.md
            ├── resources
            └── tests
                ├── main_test.bal
                └── resources
    ```

    We can remove the file `main_test.bal` for the moment, since we are not writing any tests for our service.

First let's create the services that we will use as backend endpoints.

* Create a new file named `reservation.bal` under 'appointment_service' with the following content.

**reservation.bal**

<!-- INCLUDE_CODE: src/appointment_service/reservation.bal -->

This is a simple service that would run on port 8081 and respond a JSON payload.

* Likewise, let's create a file named `payment.bal` with the following content.

**payment.bal**

<!-- INCLUDE_CODE: src/appointment_service/payment.bal -->

* Now let's open the `main.bal` file and add the following content. This is going to be our integration logic.

**main.bal**

<!-- INCLUDE_CODE: src/appointment_service/main.bal -->

Here we are calling the two services we created earlier, using the endpoints ‘reservationEP’ and ‘paymentEP’.

## Run the Integration

* First let’s build the module. While being in the service-orchestration directory, execute the following command.

    ```bash
    $ ballerina build appointment_service
    ```

This would create the executables. 

* Now run the .jar file created in the above step.

    ```bash
    $ java -jar target/bin/appointment_service.jar
    ```

Now we can see three service have started on ports 8081, 8082, and 9090. 

* Let’s access the `doctorAppoinment` service by executing the following curl command.

    ```bash
    $ curl -H 'Content-Type:application/json' http://localhost:9090/doctorAppoinment/reservation --data '{"name":"Thomas Colins", "doctor":"John Doe", "date":"30-09-2019", "cardNum":"1234567"}'
    ```

    We receive a JSON response similar to the following.

    ```json
    {
                "payment_status": "settled",
                "payment_id": "b7981676-c1ca-4380-bc31-1725eb121d1a",
                "appointmentId": "1001",
                "patient_name": "Thomas Colins",
                "date": "30-09-2019",
                "time": "3.00pm",
                "doctor_name": "John Doe",
                "fee": "1000.00"
    }
    ```