// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

package TravelAgency;

import ballerina.net.http;

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
    @http:resourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    resource arrangeTour (http:Connection connection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        // Try parsing the JSON payload from the user request
        json inReqPayload = inRequest.getJsonPayload();
        json arrivalDate = inReqPayload.ArrivalDate;
        json departureDate = inReqPayload.DepartureDate;
        json from = inReqPayload.From;
        json to = inReqPayload.To;
        json vehicleType = inReqPayload.VehicleType;
        json location = inReqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || from == null || to == null || vehicleType == null ||
            location == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = connection.respond(outResponse);
            return;
        }

        // Out request payload for Airline reservation service
        json flightPayload = {"ArrivalDate":arrivalDate, "DepartureDate":departureDate, "From":from, "To":to};
        // Out request payload for Hotel reservation service
        json hotelPayload = {"ArrivalDate":arrivalDate, "DepartureDate":departureDate, "Location":location};
        // Out request payload for Car rental service
        json vehiclePayload = {"ArrivalDate":arrivalDate, "DepartureDate":departureDate, "VehicleType":vehicleType};

        json jsonFlightResponse;
        json jsonVehicleResponse;
        json jsonHotelResponse;
        json miramarJsonResponse;
        json aqueenJsonResponse;
        json elizabethJsonResponse;
        json jsonFlightResponseEmirates;
        json jsonFlightResponseAsiana;
        json jsonFlightResponseQatar;

        // Airline reservation
        // Call Airline reservation service and consume different resources in parallel to check about different airways
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with airline 'Qatar Airways'
            worker qatarWorker {
                http:OutRequest req = {};
                http:InResponse respWorkerQatar = {};
                // Out request payload
                req.setJsonPayload(flightPayload);
                // Send a POST request to 'Qatar Airways' and get the results
                respWorkerQatar, _ = airlineReservationEP.post("/qatarAirways", req);
                // Reply to the join block from this worker - Send the response from 'Qatar Airways'
                respWorkerQatar -> fork;
            }

            // Worker to communicate with airline 'Asiana'
            worker asianaWorker {
                http:OutRequest req = {};
                http:InResponse respWorkerAsiana = {};
                // Out request payload
                req.setJsonPayload(flightPayload);
                // Send a POST request to 'Asiana' and get the results
                respWorkerAsiana, _ = airlineReservationEP.post("/asiana", req);
                // Reply to the join block from this worker - Send the response from 'Asiana'
                respWorkerAsiana -> fork;
            }

            // Worker to communicate with airline 'Emirates'
            worker emiratesWorker {
                http:OutRequest req = {};
                http:InResponse respWorkerEmirates = {};
                // Out request payload
                req.setJsonPayload(flightPayload);
                // Send a POST request to 'Emirates' and get the results
                respWorkerEmirates, _ = airlineReservationEP.post("/emirates", req);
                // Reply to the join block from this worker - Send the response from 'Emirates'
                respWorkerEmirates -> fork;
            }
        } join (all) (map airlineResponses) {
            // Wait until the responses received from all the workers running in parallel

            int qatarPrice;
            int asianaPrice;
            int emiratesPrice;

            // Get the response and price for airline 'Qatar Airways'
            if (airlineResponses["qatarWorker"] != null) {
                var resQatarWorker, _ = (any[])airlineResponses["qatarWorker"];
                var responseQatar, _ = (http:InResponse)(resQatarWorker[0]);
                jsonFlightResponseQatar = responseQatar.getJsonPayload();
                qatarPrice, _ = (int)jsonFlightResponseQatar.Price;
            }

            // Get the response and price for airline 'Asiana'
            if (airlineResponses["asianaWorker"] != null) {
                var resAsianaWorker, _ = (any[])airlineResponses["asianaWorker"];
                var responseAsiana, _ = (http:InResponse)(resAsianaWorker[0]);
                jsonFlightResponseAsiana = responseAsiana.getJsonPayload();
                asianaPrice, _ = (int)jsonFlightResponseAsiana.Price;
            }

            // Get the response and price for airline 'Emirates'
            if (airlineResponses["emiratesWorker"] != null) {
                var resEmiratesWorker, _ = (any[])airlineResponses["emiratesWorker"];
                var responseEmirates, _ = ((http:InResponse)(resEmiratesWorker[0]));
                jsonFlightResponseEmirates = responseEmirates.getJsonPayload();
                emiratesPrice, _ = (int)jsonFlightResponseEmirates.Price;

            }

            // Select the airline with the least price
            if (qatarPrice < asianaPrice) {
                if (qatarPrice < emiratesPrice) {
                    jsonFlightResponse = jsonFlightResponseQatar;
                }
            } else {
                if (qatarPrice < emiratesPrice) {
                    jsonFlightResponse = jsonFlightResponseAsiana;
                }
                else {
                    jsonFlightResponse = jsonFlightResponseEmirates;
                }
            }
        }

        // Hotel reservation
        // Call Hotel reservation service and consume different resources in parallel to check about different hotels
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with hotel 'Miramar'
            worker miramar {
                http:OutRequest req = {};
                http:InResponse respWorkerMiramar = {};
                // Out request payload
                req.setJsonPayload(hotelPayload);
                // Send a POST request to 'Asiana' and get the results
                respWorkerMiramar, _ = hotelReservationEP.post("/miramar", req);
                // Reply to the join block from this worker - Send the response from 'Asiana'
                respWorkerMiramar -> fork;
            }

            // Worker to communicate with hotel 'Aqueen'
            worker aqueen {
                http:OutRequest req = {};
                http:InResponse respWorkerAqueen = {};
                // Out request payload
                req.setJsonPayload(hotelPayload);
                // Send a POST request to 'Aqueen' and get the results
                respWorkerAqueen, _ = hotelReservationEP.post("/aqueen", req);
                // Reply to the join block from this worker - Send the response from 'Aqueen'
                respWorkerAqueen -> fork;
            }

            // Worker to communicate with hotel 'Elizabeth'
            worker elizabeth {
                http:OutRequest req = {};
                http:InResponse respWorkerElizabeth = {};
                // Out request payload
                req.setJsonPayload(hotelPayload);
                // Send a POST request to 'Elizabeth' and get the results
                respWorkerElizabeth, _ = hotelReservationEP.post("/elizabeth", req);
                // Reply to the join block from this worker - Send the response from 'Elizabeth'
                respWorkerElizabeth -> fork;
            }
        } join (all) (map hotelResponses) {
            // Wait until the responses received from all the workers running in parallel

            int miramarDistance;
            int aqueenDistance;
            int elizabethDistance;

            // Get the response and distance to the preferred location from the hotel 'Miramar'
            if (hotelResponses["miramar"] != null) {
                var resMiramarWorker, _ = (any[])hotelResponses["miramar"];
                var responseMiramar, _ = (http:InResponse)(resMiramarWorker[0]);
                miramarJsonResponse = responseMiramar.getJsonPayload();
                miramarDistance, _ = (int)miramarJsonResponse.DistanceToLocation;
            }

            // Get the response and distance to the preferred location from the hotel 'Aqueen'
            if (hotelResponses["aqueen"] != null) {
                var resAqueenWorker, _ = (any[])hotelResponses["aqueen"];
                var responseAqueen, _ = (http:InResponse)(resAqueenWorker[0]);
                aqueenJsonResponse = responseAqueen.getJsonPayload();
                aqueenDistance, _ = (int)aqueenJsonResponse.DistanceToLocation;
            }

            // Get the response and distance to the preferred location from the hotel 'Elizabeth'
            if (hotelResponses["elizabeth"] != null) {
                var resElizabethWorker, _ = (any[])hotelResponses["elizabeth"];
                var responseElizabeth, _ = ((http:InResponse)(resElizabethWorker[0]));
                elizabethJsonResponse = responseElizabeth.getJsonPayload();
                elizabethDistance, _ = (int)elizabethJsonResponse.DistanceToLocation;
            }

            // Select the hotel with the lowest distance
            if (miramarDistance < aqueenDistance) {
                if (miramarDistance < elizabethDistance) {
                    jsonHotelResponse = miramarJsonResponse;
                }
            } else {
                if (aqueenDistance < elizabethDistance) {
                    jsonHotelResponse = aqueenJsonResponse;
                }
                else {
                    jsonHotelResponse = elizabethJsonResponse;
                }
            }
        }

        // Car rental
        // Call Car rental service and consume different resources in parallel to check about different companies
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with Company 'DriveSg'
            worker driveSg {
                http:OutRequest req = {};
                http:InResponse respWorkerDriveSg = {};
                // Out request payload
                req.setJsonPayload(vehiclePayload);
                // Send a POST request to 'DriveSg' and get the results
                respWorkerDriveSg, _ = carRentalEP.post("/driveSg", req);
                // Reply to the join block from this worker - Send the response from 'DriveSg'
                respWorkerDriveSg -> fork;
            }

            // Worker to communicate with Company 'DreamCar'
            worker dreamCar {
                http:OutRequest req = {};
                http:InResponse respWorkerDreamCar = {};
                // Out request payload
                req.setJsonPayload(vehiclePayload);
                // Send a POST request to 'DreamCar' and get the results
                respWorkerDreamCar, _ = carRentalEP.post("/dreamCar", req);
                // Reply to the join block from this worker - Send the response from 'DreamCar'
                respWorkerDreamCar -> fork;
            }

            // Worker to communicate with Company 'Sixt'
            worker sixt {
                http:OutRequest req = {};
                http:InResponse respWorkerSixt = {};
                // Out request payload
                req.setJsonPayload(vehiclePayload);
                // Send a POST request to 'Sixt' and get the results
                respWorkerSixt, _ = carRentalEP.post("/sixt", req);
                // Reply to the join block from this worker - Send the response from 'Sixt'
                respWorkerSixt -> fork;
            }
        } join (some 1) (map vehicleResponses) {
            // Get the first responding worker

            // Get the response from company 'DriveSg' if not null
            if (vehicleResponses["driveSg"] != null) {
                var resDriveSgWorker, _ = (any[])vehicleResponses["driveSg"];
                var responseDriveSg, _ = (http:InResponse)(resDriveSgWorker[0]);
                jsonVehicleResponse = responseDriveSg.getJsonPayload();
            } else if (vehicleResponses["dreamCar"] != null) {
                // Get the response from company 'DreamCar' if not null
                var resDreamCarWorker, _ = (any[])vehicleResponses["dreamCar"];
                var responseDreamCar, _ = (http:InResponse)(resDreamCarWorker[0]);
                jsonVehicleResponse = responseDreamCar.getJsonPayload();
            } else if (vehicleResponses["sixt"] != null) {
                // Get the response from company 'Sixt' if not null
                var resSixtWorker, _ = (any[])vehicleResponses["sixt"];
                var responseSixt, _ = ((http:InResponse)(resSixtWorker[0]));
                jsonVehicleResponse = responseSixt.getJsonPayload();
            }
        }

        // Construct the client response
        json clientResponse = {
                                  "Flight":jsonFlightResponse,
                                  "Hotel":jsonHotelResponse,
                                  "Vehicle":jsonVehicleResponse
                              };

        // Response payload
        outResponse.setJsonPayload(clientResponse);
        // Send the response to the client
        _ = connection.respond(outResponse);
    }
}
