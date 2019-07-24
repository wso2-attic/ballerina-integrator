#!/usr/bin/env bash

HOME=`pwd`

# Comment this line if do not want to build the project again.
mvn clean install -f $HOME/pom.xml

java -jar $HOME/target/www-builder-1.0-jar-with-dependencies.jar
