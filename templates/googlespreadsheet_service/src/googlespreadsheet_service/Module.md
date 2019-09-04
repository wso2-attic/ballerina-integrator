# Google Spreadsheet Connector Service

This template demonstrates on how to use Google Spreadsheet connector

## How to run the template

1. Alter the config file `src/googlespreadsheet_service/resources/ballerina.conf` as per the requirement.

2. Execute the following command to run the service.
    ```bash
    ballerina run --config src/googlespreadsheet_service/resources/ballerina.conf googlespreadsheet_service
    ```
3. Invoke the service with the following curl requests.
    1. Create a new spreadsheet
        ```bash
        curl -v -X POST http://localhost:9090/spreadsheets/<SPREADSHEET_NAME>

        e.g: curl -v -X POST http://localhost:9090/spreadsheets/firstSpreadsheet
        ```
    2. Add a new worksheet
        ```bash
        curl -v -X POST http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_NAME>

        e.g: curl -v -X POST http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet
        ```
    3. View a spreadsheet
        ```bash
        curl -X GET http://localhost:9090/spreadsheets/<SPREADSHEET_ID>

        e.g: curl -X GET http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY
        ```
    4. Add values into a worksheet
        ```bash
        curl -H "Content-Type: application/json" \
          -X PUT \
          -d '[["Name", "Score"], ["Keetz", "12"], ["Niro", "78"], ["Nisha", "98"], ["Kana", "86"]]' \
          http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>

        e.g:
        curl -H "Content-Type: application/json" \
          -X PUT \
          -d '[["Name", "Score"], ["Keetz", "12"], ["Niro", "78"], ["Nisha", "98"], ["Kana", "86"]]' \
          http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/A1/B5
        ```
    4. Get values from worksheet
        ```bash
        curl -X GET http://localhost:9090/spreadsheets/worksheet/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>

        e.g: curl -X GET http://localhost:9090/spreadsheets/column/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/B
        ```
    5. Retrieve values of a column
        ```bash
        curl -X GET http://localhost:9090/spreadsheets/column/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<COLUMN_NAME>
        ```
    6. Retrieve values of a row
        ```bash
        curl -X GET http://localhost:9090/spreadsheets/row/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<COLUMN_NAME>/<ROW_NAME>

        e.g: curl -X GET http://localhost:9090/spreadsheets/row/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/2
        ```
    7. Add value into a cell
        ```bash
        curl -H "Content-Type: text/plain" \
          -X PUT \
          -d 'Test Value' \
          http://localhost:9090/spreadsheets/cell/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>

        e.g:
        curl -H "Content-Type: text/plain" \
          -X PUT \
          -d 'Test Value' \
          http://localhost:9090/spreadsheets/cell/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/C/2
        ```
    8. Retrieve value of a cell
         ```bash
        curl -X GET http://localhost:9090/spreadsheets/cell/<SPREADSHEET_ID>/<WORKSHEET_NAME>/<TOP_LEFT_CELL>/<BOTTOM_RIGHT_CELL>

        e.g: curl -X GET http://localhost:9090/spreadsheets/cell/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/firstWorksheet/C/2
        ```
    9. Delete a worksheet
        ```bash
        curl -X DELETE http://localhost:9090/spreadsheets/<SPREADSHEET_ID>/<WORKSHEET_ID>

        e.g: curl -X DELETE http://localhost:9090/spreadsheets/1AoOHLyn3Ds6do6UMq8t_pv20RrRwNV4aoqQVI_Z5xKY/1636241809
        ```
