import ballerina/config;
import ballerina/io;
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

public function main() {
    // Sample BAPI Request
    xml bapi = xml `<BAPI_DOCUMENT_GETLIST></BAPI_DOCUMENT_GETLIST>`;
    // Outbound BAPI Request
    var bapiResult = sapProducer->sendBapi(bapi, true);
    if (bapiResult is error) {
        io:println(bapiResult.detail()?.message);
    } else {
        io:println("Successful: " + bapiResult.toString());
    }

    // Outbound IDoc Request
    int idocVersion = 3;
    // Sample IDoc Message
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
    var idocResult = sapProducer->sendIdoc(idoc, idocVersion);
    if (idocResult is error) {
        io:println(idocResult.detail()?.message);
    } else {
        io:println("Successful: " + idocResult.toString());
    }
}
