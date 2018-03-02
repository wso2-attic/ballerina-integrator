package TravelAgency;

import ballerina.net.http;
import ballerina.log;

// Travel agency service to arrange a complete tour for a user
@http:configuration {basePath:"/travel", port:9090}
service<http> travelAgencyService {

    // Endpoint to communicate with Airline reservation service
    endpoint<http:HttpClient> airlineReservationEP {
        create http:HttpClient("http://localhost:9091/airline", {});
    }

    // Endpoint to communicate with Hotel reservation service
    endpoint<http:HttpClient> hotelReservationEP {
        create http:HttpClient("http://localhost:9092/hotel", {});
    }

    // Endpoint to communicate with Car rental service
    endpoint<http:HttpClient> carRentalEP {
        create http:HttpClient("http://localhost:9093/car", {});
    }

    // Resource to arrange a tour
    @http:resourceConfig {methods:["POST"]}
    resource arrangeTour (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};
        string name;
        json hotelPreference;
        json airlinePreference;
        json carPreference;
        // Json payload format for an http out request
        json outReqPayload = {"Name":"", "ArrivalDate":"", "DepartureDate":"", "Preference":""};

        // Try parsing the JSON payload from the user request
        try {
            log:printInfo("Parsing request payload");
            json inReqPayload = inRequest.getJsonPayload();
            name = inReqPayload.Name.toString();
            outReqPayload.Name = name;
            outReqPayload.ArrivalDate = inReqPayload.ArrivalDate.toString();
            outReqPayload.DepartureDate = inReqPayload.DepartureDate.toString();
            airlinePreference = inReqPayload.Preference.Airline.toString();
            hotelPreference = inReqPayload.Preference.Accommodation.toString();
            carPreference = inReqPayload.Preference.Car.toString();
            log:printInfo("Successfully parsed; Username: " + name);
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
            log:printWarn("Failed to parse! Bad user request\n");
            return;
        }


        // Reserve airline ticket for the user by calling Airline reservation service
        log:printInfo("Reserving airline ticket for user: " + name);
        http:OutRequest outReqAirline = {};
        http:InResponse inResAirline = {};
        // construct the payload
        json outReqPayloadAirline = outReqPayload;
        outReqPayloadAirline.Preference = airlinePreference;
        outReqAirline.setJsonPayload(outReqPayloadAirline);

        // Send a post request to airlineReservationService with appropriate payload and get response
        inResAirline, _ = airlineReservationEP.post("/reserve", outReqAirline);

        // Get the reservation status
        string airlineReservationStatus = inResAirline.getJsonPayload().Status.toString();
        // If reservation status is negative, send a failure response to user
        if (airlineReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve airline! " +
                                                  "Provide a valid 'Preference' for 'Airline' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to reserve ticket\n");
            return;
        }
        log:printInfo("Airline reservation successful!");


        // Reserve hotel room for the user by calling Hotel reservation service
        log:printInfo("Reserving hotel room for user: " + name);
        http:OutRequest outReqHotel = {};
        http:InResponse inResHotel = {};
        // construct the payload
        json outReqPayloadHotel = outReqPayload;
        outReqPayloadHotel.Preference = hotelPreference;
        outReqHotel.setJsonPayload(outReqPayloadHotel);

        // Send a post request to hotelReservationService with appropriate payload and get response
        inResHotel, _ = hotelReservationEP.post("/reserve", outReqHotel);

        // Get the reservation status
        string hotelReservationStatus = inResHotel.getJsonPayload().Status.toString();
        // If reservation status is negative, send a failure response to user
        if (hotelReservationStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to reserve hotel! " +
                                                  "Provide a valid 'Preference' for 'Accommodation' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to reserve room\n");
            return;
        }
        log:printInfo("Hotel reservation successful!");


        // Renting car for the user by calling Car rental service
        log:printInfo("Renting car for user: " + name);
        http:OutRequest outReqCar = {};
        http:InResponse inResCar = {};
        // construct the payload
        json outReqPayloadCar = outReqPayload;
        outReqPayloadCar.Preference = carPreference;
        outReqCar.setJsonPayload(outReqPayloadCar);

        // Send a post request to carRentalService with appropriate payload and get response
        inResCar, _ = carRentalEP.post("/rent", outReqCar);

        // Get the rental status
        string carRentalStatus = inResCar.getJsonPayload().Status.toString();
        // If rental status is negative, send a failure response to user
        if (carRentalStatus.equalsIgnoreCase("Failed")) {
            outResponse.setJsonPayload({"Message":"Failed to rent car! " +
                                                  "Provide a valid 'Preference' for 'Car' and try again"});
            _ = connection.respond(outResponse);
            log:printWarn("Cannot arrange tour for user: " + name + "; Failed to rent car\n");
            return;
        }
        log:printInfo("Car rental successful!");


        // If all three services response positive status, send a successful message to the user
        outResponse.setJsonPayload({"Message":"Congratulations! Your journey is ready!!"});
        _ = connection.respond(outResponse);
        log:printInfo("Successfully arranged tour for user: " + name + " !!\n");
    }
}
