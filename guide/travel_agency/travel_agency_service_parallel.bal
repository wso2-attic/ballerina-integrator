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

import ballerina/http;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"travel_agency_service",
//    tag:"v1.0"
//}

//@kubernetes:Ingress {
//  hostname:"ballerina.guides.io",
//  name:"ballerina-guides-travel-agency-service",
//  path:"/"
//}
//
//@kubernetes:Service {
//  serviceType:"NodePort",
//  name:"ballerina-guides-travel-agency-service"
//}
//
//@kubernetes:Deployment {
//  image:"ballerina.guides.io/travel_agency_service:v1.0",
//  name:"ballerina-guides-travel-agency-service"
//}

// Service endpoint
endpoint http:Listener travelAgencyEP {
    port:9090
};

// Client endpoint to communicate with Airline reservation service
endpoint http:Client airlineEP {
    url:"http://localhost:9091/airline"
};

// Client endpoint to communicate with Hotel reservation service
endpoint http:Client hotelEP {
    url:"http://localhost:9092/hotel"
};

// Client endpoint to communicate with Car rental service
endpoint http:Client carRentalEP {
    url:"http://localhost:9093/car"
};

// Travel agency service to arrange a complete tour for a user
@http:ServiceConfig {basePath:"/travel"}
service<http:Service> travelAgencyService bind travelAgencyEP {

    // Resource to arrange a tour
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"], produces:["application/json"]}
    arrangeTour (endpoint client, http:Request inRequest) {
        http:Response outResponse;
        json inReqPayload;

        // Try parsing the JSON payload from the request
        match inRequest.getJsonPayload() {
            // Valid JSON payload
            json payload => inReqPayload = payload;
            // NOT a valid JSON payload
            any => {
                outResponse.statusCode = 400;
                outResponse.setJsonPayload({"Message":"Invalid payload - Not a valid JSON payload"});
                _ = client -> respond(outResponse);
                done;
            }
        }

        json arrivalDate = inReqPayload.ArrivalDate;
        json departureDate = inReqPayload.DepartureDate;
        json fromPlace = inReqPayload.From;
        json toPlace = inReqPayload.To;
        json vehicleType = inReqPayload.VehicleType;
        json location = inReqPayload.Location;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (arrivalDate == null || departureDate == null || fromPlace == null || toPlace == null ||
            vehicleType == null || location == null) {
            outResponse.statusCode = 400;
            outResponse.setJsonPayload({"Message":"Bad Request - Invalid Payload"});
            _ = client -> respond(outResponse);
            done;
        }

        // Out request payload for Airline reservation service
        json flightPayload = {"ArrivalDate":arrivalDate, "DepartureDate":departureDate, "From":fromPlace, "To":toPlace};
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
        // Call Airline reservation service and consume different resources in parallel to check different airways
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with airline 'Qatar Airways'
            worker qatarWorker {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(flightPayload);
                // Send a POST request to 'Qatar Airways' and get the results
                http:Response respWorkerQatar = check airlineEP -> post("/qatarAirways", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Qatar Airways'
                respWorkerQatar -> fork;
            }

            // Worker to communicate with airline 'Asiana'
            worker asianaWorker {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(flightPayload);
                // Send a POST request to 'Asiana' and get the results
                http:Response respWorkerAsiana = check airlineEP -> post("/asiana", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Asiana'
                respWorkerAsiana -> fork;
            }

            // Worker to communicate with airline 'Emirates'
            worker emiratesWorker {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(flightPayload);
                // Send a POST request to 'Emirates' and get the results
                http:Response respWorkerEmirates = check airlineEP -> post("/emirates", request = outReq);
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
                var resQatar = check <http:Response>(airlineResponses["qatarWorker"]);
                jsonFlightResponseQatar = check resQatar.getJsonPayload();
                match jsonFlightResponseQatar.Price {
                    int intVal => qatarPrice = intVal;
                    any otherVals => qatarPrice = -1;
                }
            }

            // Get the response and price for airline 'Asiana'
            if (airlineResponses["asianaWorker"] != null) {
                var resAsiana = check <http:Response>(airlineResponses["asianaWorker"]);
                jsonFlightResponseAsiana = check resAsiana.getJsonPayload();
                match jsonFlightResponseAsiana.Price {
                    int intVal => asianaPrice = intVal;
                    any otherVals => asianaPrice = -1;
                }
            }

            // Get the response and price for airline 'Emirates'
            if (airlineResponses["emiratesWorker"] != null) {
                var resEmirates = check <http:Response>(airlineResponses["emiratesWorker"]);
                jsonFlightResponseEmirates = check resEmirates.getJsonPayload();
                match jsonFlightResponseEmirates.Price {
                    int intVal => emiratesPrice = intVal;
                    any otherVals => emiratesPrice = -1;
                }
            }

            // Select the airline with the least price
            if (qatarPrice < asianaPrice) {
                if (qatarPrice < emiratesPrice) {
                    jsonFlightResponse = jsonFlightResponseQatar;
                }
            } else {
                if (asianaPrice < emiratesPrice) {
                    jsonFlightResponse = jsonFlightResponseAsiana;
                }
                else {
                    jsonFlightResponse = jsonFlightResponseEmirates;
                }
            }
        }

        // Hotel reservation
        // Call Hotel reservation service and consume different resources in parallel to check different hotels
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with hotel 'Miramar'
            worker miramar {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(hotelPayload);
                // Send a POST request to 'Asiana' and get the results
                http:Response respWorkerMiramar = check hotelEP -> post("/miramar", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Asiana'
                respWorkerMiramar -> fork;
            }

            // Worker to communicate with hotel 'Aqueen'
            worker aqueen {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(hotelPayload);
                // Send a POST request to 'Aqueen' and get the results
                http:Response respWorkerAqueen = check hotelEP -> post("/aqueen", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Aqueen'
                respWorkerAqueen -> fork;
            }

            // Worker to communicate with hotel 'Elizabeth'
            worker elizabeth {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(hotelPayload);
                // Send a POST request to 'Elizabeth' and get the results
                http:Response respWorkerElizabeth = check hotelEP -> post("/elizabeth", request = outReq);
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
                var responseMiramar = check <http:Response>(hotelResponses["miramar"]);
                miramarJsonResponse = check responseMiramar.getJsonPayload();
                match miramarJsonResponse.DistanceToLocation {
                    int intVal => miramarDistance = intVal;
                    any otherVals => miramarDistance = -1;
                }
            }

            // Get the response and distance to the preferred location from the hotel 'Aqueen'
            if (hotelResponses["aqueen"] != null) {
                var responseAqueen = check <http:Response>(hotelResponses["aqueen"]);
                aqueenJsonResponse = check responseAqueen.getJsonPayload();
                match aqueenJsonResponse.DistanceToLocation {
                    int intVal => aqueenDistance = intVal;
                    any otherVals => aqueenDistance = -1;
                }
            }

            // Get the response and distance to the preferred location from the hotel 'Elizabeth'
            if (hotelResponses["elizabeth"] != null) {
                var responseElizabeth = check <http:Response>(hotelResponses["elizabeth"]);
                elizabethJsonResponse = check responseElizabeth.getJsonPayload();
                match elizabethJsonResponse.DistanceToLocation {
                    int intVal => elizabethDistance = intVal;
                    any otherVals => elizabethDistance = -1;
                }
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
        // Call Car rental service and consume different resources in parallel to check different companies
        // Fork - Join to run parallel workers and join the results
        fork {
            // Worker to communicate with Company 'DriveSg'
            worker driveSg {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(vehiclePayload);
                // Send a POST request to 'DriveSg' and get the results
                http:Response respWorkerDriveSg = check carRentalEP -> post("/driveSg", request = outReq);
                // Reply to the join block from this worker - Send the response from 'DriveSg'
                respWorkerDriveSg -> fork;
            }

            // Worker to communicate with Company 'DreamCar'
            worker dreamCar {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(vehiclePayload);
                // Send a POST request to 'DreamCar' and get the results
                http:Response respWorkerDreamCar = check carRentalEP -> post("/dreamCar", request = outReq);
                // Reply to the join block from this worker - Send the response from 'DreamCar'
                respWorkerDreamCar -> fork;
            }

            // Worker to communicate with Company 'Sixt'
            worker sixt {
                http:Request outReq;
                // Out request payload
                outReq.setJsonPayload(vehiclePayload);
                // Send a POST request to 'Sixt' and get the results
                http:Response respWorkerSixt = check carRentalEP -> post("/sixt", request = outReq);
                // Reply to the join block from this worker - Send the response from 'Sixt'
                respWorkerSixt -> fork;
            }
        } join (some 1) (map vehicleResponses) {
            // Get the first responding worker

            // Get the response from company 'DriveSg' if not null
            if (vehicleResponses["driveSg"] != null) {
                var responseDriveSg = check <http:Response>(vehicleResponses["driveSg"]);
                jsonVehicleResponse = check responseDriveSg.getJsonPayload();
            } else if (vehicleResponses["dreamCar"] != null) {
                // Get the response from company 'DreamCar' if not null
                var responseDreamCar = check <http:Response>(vehicleResponses["dreamCar"]);
                jsonVehicleResponse = check responseDreamCar.getJsonPayload();
            } else if (vehicleResponses["sixt"] != null) {
                // Get the response from company 'Sixt' if not null
                var responseSixt = check <http:Response>(vehicleResponses["sixt"]);
                jsonVehicleResponse = check responseSixt.getJsonPayload();
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
        _ = client -> respond(outResponse);
    }
}
