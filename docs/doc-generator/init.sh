#!/bin/bash

JAR_NAME=$1
VERSION=$2
JAR_FULL_NAME=$JAR_NAME-$VERSION-jar-with-dependencies.jar
echo "Running jar file " $JAR_FULL_NAME
java -jar target/$JAR_FULL_NAME > target/execution.log 2>&1

if (grep -q "Invalid file path" target/execution.log)
  then
    echo "Invalid file path in INCLUDE_CODE tag. Mentioned file does not exists in the project. See more at execution.log"
    exit 1
  fi
  