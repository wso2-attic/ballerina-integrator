package TravelAgency.HotelReservation;

import ballerina.net.http;
import ballerina.log;

// Available room types
const string AC = "Air Conditioned";
const string Normal = "Normal";

// Hotel reservation service to reserve hotel rooms
@http:configuration {basePath:"/hotel", port:9092}
service<http> hotelReservationService {

    // Resource to reserve a room
    @http:resourceConfig {methods:["POST"], path:"/reserve"}
    resource reserveRoom (http:Connection connection, http:InRequest request) {
        http:OutResponse response = {};
        string name;
        string arrivalDate;
        string departureDate;
        string preferredRoomType;

        // Try parsing the JSON payload from the request
        try {
            json payload = request.getJsonPayload();
            name = payload.Name.toString();
            arrivalDate = payload.ArrivalDate.toString();
            departureDate = payload.DepartureDate.toString();
            preferredRoomType = payload.Preference.toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(response);
            return;
        }

        // Mock logic
        // If request is for an available room type, send a reservation successful status
        if (preferredRoomType.equalsIgnoreCase(AC) || preferredRoomType.equalsIgnoreCase(Normal)) {
            log:printInfo("Successfully reserved hotel room for user: " + name);
            response.setJsonPayload({"Status":"Success"});
        }
        else {
            // If request is not for an available room type, send a reservation failure status
            log:printWarn("Failed to reserve hotel room for user: " + name);
            response.setJsonPayload({"Status":"Failed"});
        }
        // Send the response
        _ = connection.respond(response);
    }
}
