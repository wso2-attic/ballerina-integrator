# declare STRING variable
STRING="Downloading ballerina..."
BALLERINA_PACKAGE_NAME="ballerina-tools-0.964.0"
#print variable on a screen
echo $STRING
#download ballerina distro
wget https://ballerinalang.org/downloads/ballerina-tools/$BALLERINA_PACKAGE_NAME.zip
#unzip the zip file
unzip $BALLERINA_PACKAGE_NAME.zip
