#!/bin/bash
# ---------------------------------------------------------------------------
#  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


declare -a dirs
i=1
for d in */
do
    dirs[i++]="${d%/}"
done
echo "There are ${#dirs[@]} test suites in the current path"

for((i=1;i<=${#dirs[@]};i++))
do
	cd ${dirs[i]}
    echo  "Executing ${dirs[i]} testsuite"
    cd BallerinaProject
    ballerina build -a
    java -jar target/bin/*.jar > service.log &
    cd ..
    cd TestProject
    mvn clean install
    kill $(lsof -t -i:9090)
    cd ../..
done
