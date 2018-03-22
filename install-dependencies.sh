#!/bin/bash
# declare STRING variable
STRING="Downloading ballerina..."
BALLERINA_VERSION="ballerina-0.964.0"
#print variable on a screen
echo $STRING
#download ballerina distro
wget https://ballerinalang.org/downloads/ballerina-runtime/$BALLERINA_VERSION.zip
#unzip the zip file
unzip $BALLERINA_VERSION.zip

export PATH=$PATH:$(pwd)/$BALLERINA_VERSION/bin
echo $PATH
ballerina version