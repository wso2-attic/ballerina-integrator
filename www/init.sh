#!/bin/bash

HOME=`pwd`
java -jar $HOME/target/www-builder-1.0-jar-with-dependencies.jar > execution.log 2>&1 

if (grep -q "Invalid file path" execution.log)
  then
    echo "Invalid file path in INCLUDE_CODE tag. Mentioned file does not exists in the project. See more at execution.log"
    exit 1
  fi
  