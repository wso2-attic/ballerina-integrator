@echo off
setlocal enabledelayedexpansion
REM Copyright (c) 2019, WSO2 Inc. (http://wso2.org) All Rights Reserved.
REM
REM WSO2 Inc. licenses this file to you under the Apache License,
REM Version 2.0 (the "License"); you may not use this file except
REM in compliance with the License.
REM You may obtain a copy of the License at
REM
REM http://www.apache.org/licenses/LICENSE-2.0

REM Unless required by applicable law or agreed to in writing,
REM software distributed under the License is distributed on an
REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
REM KIND, either express or implied.  See the License for the
REM specific language governing permissions and limitations
REM under the License.

REM ----------------------------------------------------------------------------
REM Build Ballerina Integrator Tests
REM ----------------------------------------------------------------------------

set BI_CONTENT_HOME=%cd%
set OUTPUT_FILE=output\testResults

call :executeTests ..\output

:clearDirectory
if exist %1 rmdir /S /Q %1
exit /b 0

:createDirectory
if exist %1 call :clearDirectory %~1
mkdir %1
exit /b 0

:findIfFailedToRunTests
findstr /r /c:"Running tests" %OUTPUT_FILE% > NULL
set ERRORLEVEL=%errorlevel%
IF ERRORLEVEL==1 (
    set result=%%g
    echo Failure in %~1: %~2
    exit /b 1
) else (
    echo No failures in %~1: %~2 tests
)
exit /b 0

:findTestFailures
findstr /r /c:"[1-9][0-9]* failing" %OUTPUT_FILE% > NULL
set ERRORLEVEL=%errorlevel%
IF ERRORLEVEL==1 (
    call :findIfFailedToRunTests %~1 %~2
) else (
    set result=%%g
    echo Failure in %~1: %~2
    exit /b 1
)
exit /b 0

:executeTests
set config_file=%BI_CONTENT_HOME%\resources\config.json
call :createDirectory %~1

echo "     _____         _        "
echo "    |_   _|__  ___| |_ ___  "
echo "      | |/ _ \/ __| __/ __| "
echo "      | |  __/\__ \ |_\__ \ "
echo "      |_|\___||___/\__|___/ "
echo "                            "

call :createDirectory %BI_CONTENT_HOME%\output

for /f "tokens=*" %%a in ('jq ".tutorials | keys | .[]" %config_file%') do (

    for /f "tokens=*" %%b in ('jq -r ".tutorials[%%a]" %config_file%') do ( set tutorial=%%b )

    for /f "tokens=*" %%c in ('jq -r ".tutorials[%%a].path" %config_file%') do ( set tutorialpath=%%c )

    for /f "tokens=*" %%d in ('jq -r ".tutorials[%%a].skipTests" %config_file%') do ( set skiptests=%%d )

    set fullpath=%BI_CONTENT_HOME%/!tutorialpath!
    set fullpath=!fullpath:/=\!

    set skiptests=!skiptests:~0,-1!

    echo Executing !fullpath!

    cd !fullpath!
    call :createDirectory output

    for /f "tokens=*" %%e in ('jq ".tutorials[%%a].modules | keys | .[]" %config_file%') do (
        for /f "tokens=*" %%f in ('jq -r ".tutorials[%%a].modules[%%e]" %config_file%') do (
            set module=%%f

            if /I "!skiptests!"=="true" (
                echo Skipping tests...
                call ballerina build --skip-tests !module! >> %OUTPUT_FILE%
                call :findTestFailures !tutorialpath! !module!
            ) else (
                call ballerina build !module! >> %OUTPUT_FILE%
                call :findTestFailures !tutorialpath! !module!
            )
        )
    )

    echo ------End of executing !tutorialpath! tests-----
    call type output\testResults >> %BI_CONTENT_HOME%\output\completeTestResults.log
)

endlocal
