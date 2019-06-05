### Sending_message_to_a_simple_service


| Test Case ID| Test Case| Test Case Description| Status|
| ----------| --------| ----------| ------|
| TC001 | Verify the response when a valid name is sent.| **Given**:Hello service should be up and running. </br> **When**:A input should be sent to the service with a valid text. </br> **Then**:User should get a valid output.| Automated|
| TC002 | Verify the response when a valid space character is sent.| **Given**:Hello service should be up and running. </br> **When**:A input should be sent to the service with valid space character. </br> **Then**:User should get a valid output.| Automated|
| NTC001 | Verify the response when an invalid empty string is sent.| **Given**:Hello service should be up and running. </br> **When**:A input should be sent to the service with invalid empty string. </br> **Then**:It should return an error as payload is empty.| Automated|
