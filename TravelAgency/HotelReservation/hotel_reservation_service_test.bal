package TravelAgency.HotelReservation;

import ballerina.test;
import ballerina.net.http;

// Function to test Hotel reservation service
function testCarRentalService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9092/hotel", {});
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Start the Hotel reservation service
    _ = test:startService("hotelReservationService");

    // Test the 'reserveRoom' resource
    // Construct a request payload
    json payload = {
                       "Name":"Alice",
                       "ArrivalDate":"12-03-2018",
                       "DepartureDate":"13-04-2018",
                       "Preference":"Air Conditioned"
                   };

    request.setJsonPayload(payload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/reserve", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot reserve room!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Hotel reservation service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(), "{\"Status\":\"Success\"}", "Response mismatch!");
}
