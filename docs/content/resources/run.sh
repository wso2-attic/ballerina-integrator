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
    config_file=${BI_CONTENT_HOME}/resources/config.json

    clear_directory ${BI_CONTENT_HOME}/output

    echo '     _____         _
    |_   _|__  ___| |_ ___
      | |/ _ \/ __| __/ __|
      | |  __/\__ \ |_\__ \
      |_|\___||___/\__|___/

    '

    for k in $(jq '.tutorials | keys | .[]' $config_file); do
        tutorial=$(jq -r ".tutorials[$k]" $config_file)
        path=$(jq '.path' <<< "$tutorial")
        skipTests=$(jq '.skipTests' <<< "$tutorial")

        echo "Executing $path..."

        # Remove quotes from path
        temp="${path%\"}"
        temp="${temp#\"}"

        cd ${BI_CONTENT_HOME}/$temp
        create_directory output

        for l in $(jq '.modules | keys | .[]' <<< "$tutorial"); do
            module=$(jq -r ".modules[$l]" <<< "$tutorial")

            if $skipTests ; then
                echo "Skipping tests..."
                ballerina build --skip-tests $module > output/testResults

                if (grep -q "[1-9][0-9]* failing" output/testResults)
                then
                    echo -e "failure in $path: $module \n"
                    exit 1
                else
                    echo "No failures in $path: $module tests"
                fi
            else
                ballerina build $module > output/testResults

                if (grep -q "[1-9][0-9]* failing" output/testResults) || ! (grep -q "Running tests" output/testResults)
                then
                    echo -e "failure in $path: $module \n"
                    exit 1
                else
                    echo "No failures in $path: $module tests"
                fi
            fi

        done

        echo -e "------End of executing $path tests----- \n"
        create_directory ${BI_CONTENT_HOME}/output
        cat output/testResults >> ${BI_CONTENT_HOME}/output/completeTestResults.log
    done
}

execute_tests

