package TravelAgency;

import ballerina.test;
import ballerina.net.http;

// Function to test Travel agency service
// NOTE: Run the other 3 services (Airline, Hotel and Car) before running this test
function testTravelAgencyService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9090/travel", {});
    }
    // Initialize the empty http requests and responses
    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;

    // Start the Travel agency service
    _ = test:startService("travelAgencyService");

    // Test the 'arrangeTour' resource
    // Construct a request payload
    json payload = {
                       "Name":"Alice",
                       "ArrivalDate":"12-03-2018",
                       "DepartureDate":"13-04-2018",
                       "Preference":{"Airline":"Business", "Accommodation":"Air Conditioned", "Car":"Air Conditioned"}
                   };

    request.setJsonPayload(payload);
    // Send a 'post' request and obtain the response
    response, err = httpEndpoint.post("/arrangeTour", request);
    // 'err' is expected to be null
    test:assertTrue(err == null, "Error: Cannot arrange tour!");
    // Expected response code is 200
    test:assertIntEquals(response.statusCode, 200, "Travel agency service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    test:assertStringEquals(response.getJsonPayload().toString(),
                            "{\"Message\":\"Congratulations! Your journey is ready!!\"}", "Response mismatch!");
}
