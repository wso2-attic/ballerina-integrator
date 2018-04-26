# Copyright (c) 2018, WSO2 Inc. (http://wso2.com) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

#declare STRING variable
STRING="Downloading ballerina..."
BALLERINA_VERSION="ballerina-platform-0.970.0-beta17"

#print downloading string
echo $STRING

#download Ballerina dist
wget https://product-dist.ballerina.io/nightly/$BALLERINA_VERSION.zip

#unzip the zip file
unzip $BALLERINA_VERSION.zip

export PATH=$PATH:$(pwd)/$BALLERINA_VERSION/bin

#print Ballerina version
ballerina version
