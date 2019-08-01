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
# Run Ballerina Integrator Tests
# ----------------------------------------------------------------------------
HOME=`pwd`
> $HOME/completeTestResults
source $HOME/resources/config.properties

cd $path1
ballerina init
sed -i -r 's/org-name\s=\s"(.*)("$)/org-name\=\"wso2"/g' Ballerina.toml


ballerina build --skiptests util
ballerina install --no-build util

ballerina build --skiptests daos
ballerina install --no-build daos

ballerina build --skiptests healthcare
ballerina install --no-build healthcare

echo ' _____         _       
|_   _|__  ___| |_ ___ 
  | |/ _ \/ __| __/ __|
  | |  __/\__ \ |_\__ \
  |_|\___||___/\__|___/
                       
'
executionNameList=("healthcare-service" "Integration Tutorials" "backend for front-end")
executionPathList=($path1 $path2 $path3)

count=0
for i in "${executionPathList[@]}"; 
do 
	echo "Executing ${executionNameList[$count]}"
	cd $HOME/${executionPathList[$count]}
	ballerina init
	ballerina test > testResults
	if ((grep -q "[1-9][0-9]* failing" testResults) || ! (grep -q "Running tests" testResults))
	then
		echo "failure in ${executionNameList[$count]}"
		exit 1
	else 
		echo "No failures in ${executionNameList[$count]} tests"
	fi
	echo "------End of executing ${executionNameList[$count]} tests-----"
	((count++))
	cat testResults >> $HOME/completeTestResults
done;

echo `date "+%Y-%m-%d-%H:%M:%S"`" : Ballerina tests built successfully!"

ballerina uninstall wso2/daos:0.0.1
ballerina uninstall wso2/util:0.0.1
ballerina uninstall wso2/healthcare:0.0.1
