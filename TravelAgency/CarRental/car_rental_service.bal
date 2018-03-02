package TravelAgency.CarRental;

import ballerina.net.http;
import ballerina.log;

// Available car types
const string AC = "Air Conditioned";
const string Normal = "Normal";

// Car rental service to rent cars
@http:configuration {basePath:"/car", port:9093}
service<http> carRentalService {

    // Resource to rent a car
    @http:resourceConfig {methods:["POST"], path:"/rent"}
    resource rentCar (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};
        string name;
        string arrivalDate;
        string departureDate;
        string preferredType;

        // Try parsing the JSON payload from the request
        try {
            json payload = request.getJsonPayload();
            name = payload.Name.toString();
            arrivalDate = payload.ArrivalDate.toString();
            departureDate = payload.DepartureDate.toString();
            preferredType = payload.Preference.toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available car type, send a rental successful status
        if (preferredType.equalsIgnoreCase(AC) || preferredType.equalsIgnoreCase(Normal)) {
            log:printInfo("Successfully rented car for user: " + name);
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available car type, send a rental failure status
            log:printWarn("Failed to reserve rent car for user: " + name);
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
