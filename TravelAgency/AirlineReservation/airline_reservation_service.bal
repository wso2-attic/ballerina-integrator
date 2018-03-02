package TravelAgency.AirlineReservation;

import ballerina.net.http;
import ballerina.log;

// Available flight classes
const string ECONOMY = "Economy";
const string BUSINESS = "Business";
const string FIRST = "First";

// Airline reservation service to reserve airline tickets
@http:configuration {basePath:"/airline", port:9091}
service<http> airlineReservationService {

    // Resource to reserve a ticket
    @http:resourceConfig {methods:["POST"], path:"/reserve"}
    resource reserveTicket (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};
        string name;
        string arrivalDate;
        string departureDate;
        string preferredClass;

        // Try parsing the JSON payload from the request
        try {
            json payload = request.getJsonPayload();
            name = payload.Name.toString();
            arrivalDate = payload.ArrivalDate.toString();
            departureDate = payload.DepartureDate.toString();
            preferredClass = payload.Preference.toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available flight class, send a reservation successful status
        if (preferredClass.equalsIgnoreCase(ECONOMY) || preferredClass.equalsIgnoreCase(BUSINESS) ||
            preferredClass.equalsIgnoreCase(FIRST)) {
            log:printInfo("Successfully reserved airline ticket for user: " + name);
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available flight class, send a reservation failure status
            log:printWarn("Failed to reserve airline ticket for user: " + name);
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
