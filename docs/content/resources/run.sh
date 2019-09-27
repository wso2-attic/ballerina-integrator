#!/bin/bash
# Copyright (c) 2019, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------
# Build Ballerina Integrator Tests
# ----------------------------------------------------------------------------

BI_CONTENT_HOME=`pwd`
source ${BI_CONTENT_HOME}/resources/config.properties

clear_directory() {
    if [[ ! -e $1 ]]
    then
        rm -rf $1
    fi
}

create_directory() {
    if [[ ! -d $1 ]]
    then
        mkdir $1
    else
        clear_directory $1
    fi
}

execute_tests() {
    clear_directory ${BI_CONTENT_HOME}/output

    executionNameList=("healthcare-service" "exposing-several-services-as-a-single-service"
    "sending-a-simple-message-to-a-service" "routing-requests-based-on-message-content"
    "backend-for-frontend" "backend-for-frontend" "backend-for-frontend" "backend-for-frontend"
    "backend-for-frontend" "backend-for-frontend" "backend-for-frontend" "content-based-routing-advanced"
    "message-filtering" "pass-through-messaging" "scatter-gather-messaging-advanced" "asynchronous-invocation"
    "asynchronous-invocation" "parallel-service-orchestration" "parallel-service-orchestration"
    "parallel-service-orchestration" "parallel-service-orchestration" "exposing-a-rest-service"
    "service-composition" "service-composition" "service-composition" "writing-tests-using-data-providers")
    executionPathList=(${path1} ${path2} ${path3} ${path4} ${path5} ${path6} ${path7} ${path8} ${path9} ${path10} ${path11} ${path12}
    ${path13} ${path14} ${path15} ${path16} ${path17} ${path18} ${path19} ${path20} ${path21} ${path22} ${path24} ${path25}
    ${path26} ${path28})
    moduleList=("healthcare" "tutorial" "tutorial" "tutorial" "appointment_mgt" "desktop_bff"
    "medical_record_mgt" "message_mgt" "mobile_bff" "notification_mgt" "sample_data_publisher"
    "company_data_service" "message_filtering" "passthrough" "auction_service" "stock_quote_data_backend"
    "stock_quote_summary_service" "airline_reservation" "car_rental" "hotel_reservation" "travel_agency" "restful_service"
    "airline_reservation" "car_rental" "hotel_reservation" "hello_service")

    echo ' _____         _
    |_   _|__  ___| |_ ___
      | |/ _ \/ __| __/ __|
      | |  __/\__ \ |_\__ \
      |_|\___||___/\__|___/

    '

    count=0
    for i in "${executionPathList[@]}";
    do
        echo "Executing ${executionNameList[$count]}"
        cd ${BI_CONTENT_HOME}/${executionPathList[$count]}
        create_directory output
        ballerina build ${moduleList[$count]} > output/testResults
        if (grep -q "[1-9][0-9]* failing" output/testResults) || ! (grep -q "Running tests" output/testResults)
        then
            echo -e "failure in ${executionNameList[$count]} \n"
            exit 1
        else
            echo "No failures in ${executionNameList[$count]} tests"
        fi
        echo -e "------End of executing ${executionNameList[$count]} tests----- \n"
        ((count++))
        create_directory ${BI_CONTENT_HOME}/output
        cat output/testResults >> ${BI_CONTENT_HOME}/output/completeTestResults.log
    done;
}

execute_tests

