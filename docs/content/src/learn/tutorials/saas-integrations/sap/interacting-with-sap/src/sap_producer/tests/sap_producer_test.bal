import ballerina/config;
import ballerina/io;
import ballerina/test;
import wso2/sap;

sap:ProducerConfig producerConfigs = {
    destinationName: config:getAsString("DESTINATION_NAME"),
    sapclient: config:getAsString("SAP_CLIENT"),
    username: config:getAsString("USERNAME"),
    password: config:getAsString("PASSWORD"),
    ashost: config:getAsString("ASHOST"),
    sysnr: config:getAsString("SYSNR"),
    language: config:getAsString("LANGUAGE")
};

sap:Producer sapProducer = new (producerConfigs);

# Test outbound BAPI request.
@test:Config {}
function testBapiSend() {
    xml bapi = xml `<BAPI_DOCUMENT_GETLIST></BAPI_DOCUMENT_GETLIST>`;
    io:println("Testing Outbound BAPI requests.");
    var result = sapProducer->sendBapi(bapi, true);
    if (result is error) {
        test:assertTrue(false, msg = "Failed!");
    } else {
        test:assertTrue(true, msg = "Passed!");
    }
}

# Test outbound IDOC message.
@test:Config {}
function testIdocSend() {
    int idocVersion = 3;
    xml idoc = xml `<_-DSD_-ROUTEACCOUNT_CORDER002>
                        <IDOC BEGIN="1">
                            <EDI_DC40 SEGMENT="1">
                                <IDOCTYP>/DSD/ROUTEACCOUNT_CORDER002</IDOCTYP>
                            </EDI_DC40>
                            <_-DSD_-E1BPRAGENERALHD SEGMENT="1">
                                <MISSION_ID>2</MISSION_ID>
                            </_-DSD_-E1BPRAGENERALHD>
                        </IDOC>
                    </_-DSD_-ROUTEACCOUNT_CORDER002>`;
    io:println("Testing Outbound IDoc messages.");
    var result = sapProducer->sendIdoc(idoc, idocVersion);
    if (result is error) {
        io:println(result);
        test:assertTrue(false, msg = "Failed!");
    } else {
        test:assertTrue(true, msg = "Passed!");
    }
}
