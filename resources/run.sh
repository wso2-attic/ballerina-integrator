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

HOME=`pwd`
source $HOME/resources/config.properties
if [ -e $HOME/completeTestResults.log ]
then
    rm -rf $HOME/completeTestResults.log
fi

executionNameList=("healthcare-service" "exposing-several-services-as-a-single-service" 
"sending-a-simple-message-to-a-service" "routing-requests-based-on-message-content"
"backend-for-frontend" "backend-for-frontend" "backend-for-frontend" "backend-for-frontend"
"backend-for-frontend" "backend-for-frontend" "backend-for-frontend" "content-based-routing"
"message-filtering" "pass-through-messaging" "scatter-gather-messaging") 
executionPathList=($path1 $path2 $path3 $path4 $path5 $path6 $path7 $path8 $path9 $path10 $path11 $path12
$path13 $path14 $path15)
moduleList=("healthcare" "tutorial" "tutorial" "tutorial" "appointment_mgt" "desktop_bff" 
"medical_record_mgt" "message_mgt" "mobile_bff" "notification_mgt" "sample_data_publisher" 
"company_data_service" "message_filtering" "passthrough" "auction_service")

echo ' _____         _       
|_   _|__  ___| |_ ___ 
  | |/ _ \/ __| __/ __|
  | |  __/\__ \ |_\__ \
  |_|\___||___/\__|___/
                       
'

# Due to https://github.com/wso2/ballerina-integrator/issues/316, healthcare bir cache is not being created in the 
# exposing-several-services-as-a-single-service' module. Therefore, when the healthcare module is build, we have to 
# manually move the bir cache. 

#build healthcare service
echo "Executing healthcare-service"
cd $HOME/${executionPathList[0]}
ballerina build healthcare > testResults
if ((grep -q "[1-9][0-9]* failing" testResults) || ! (grep -q "Running tests" testResults))
then
	echo -e "failure in ${executionNameList[0]} \n"
	exit 1
else 
	echo "No failures in ${executionNameList[0]} tests"
fi
echo -e "------End of executing ${executionNameList[0]} tests----- \n"
((count++))
cat testResults >> $HOME/completeTestResults.log

# move cache to ballerina home
mkdir -p /home/travis/.ballerina/bir_cache/wso2/healthcare/0.1.0

cp /home/travis/build/wso2/ballerina-integrator/docs/learn/backends/healthcare-service/target/caches/bir_cache/wso2/healthcare/0.1.0/healthcare.bir /home/travis/.ballerina/bir_cache/wso2/healthcare/0.1.0 

# TODO: Count should be changed to 1 when issue (https://github.com/wso2/ballerina-integrator/issues/316) is fixed.
count=0
for i in "${executionPathList[@]}"; 
do 
	echo "Executing ${executionNameList[$count]}"
	echo "Path==> ${executionPathList[$count]}"
	cd $HOME/${executionPathList[$count]}
	ballerina build ${moduleList[$count]} > testResults
	if ((grep -q "[1-9][0-9]* failing" testResults) || ! (grep -q "Running tests" testResults))
	then
		echo -e "failure in ${executionNameList[$count]} \n"
		exit 1
	else 
		echo "No failures in ${executionNameList[$count]} tests"
	fi
	echo -e "------End of executing ${executionNameList[$count]} tests----- \n"
	((count++))
	cat testResults >> $HOME/completeTestResults.log
done;
