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
"sending-a-simple-message-to-a-service" "routing-requests-based-on-message-content" "transforming-message-content") 
executionPathList=($path1 $path2 $path3 $path4 $path5)
moduleList=("healthcare" "tutorial" "tutorial" "tutorial" "tutorial")

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
