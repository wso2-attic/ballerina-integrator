# Auto Generated Dockerfile

FROM ballerina/ballerina:0.980.1
LABEL maintainer="dev@ballerina.io"

COPY order_accepting_service.balx /home/ballerina 

COPY geronimo-j2ee-management_1.1_spec-1.0.1.jar /ballerina/runtime/bre/lib
COPY activemq-client-5.12.0.jar /ballerina/runtime/bre/lib
EXPOSE  9090

CMD ballerina run order_accepting_service.balx
