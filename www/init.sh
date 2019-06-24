#!/usr/bin/env bash

HOME=`pwd`
HUGO_VERSION=$(hugo version)

function build_www {
    mvn clean install -f $HOME/pom.xml # Comment this line if do not want to build the project again.
    java -jar $HOME/target/www-builder-1.0-jar-with-dependencies.jar
    cd $HOME/hugo-www
    hugo server -D
}

if [[ ${HUGO_VERSION} == *"Hugo Static Site Generator"* ]];
    then
        build_www
    else
        echo "You have not installed hugo. Please refer https://gohugo.io/getting-started/installing to install hugo."

fi

