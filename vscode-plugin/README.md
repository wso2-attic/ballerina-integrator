## Ballerina Integrator VSCode Plugin

#### Adding new snippets to the plugin

1 . Clone ballerina-integrator repo from GIT.

2 . Create the relevant code snippet by following the format given in the file, SnippetGenerator.java ( /vscode-plugin/src/main/java/org/wso2/integration/ballerinalangserver/SnippetsGenerator.javaorg/wso2/integration/ballerinalangserver/SnippetsGenerator).

3 . Insert it as an enum in the Snippets.java file. ( /vscode-plugin/src/main/java/org/wso2/integration/util/Snippets)

4 . Add the newly added enum value in the Snippets.java file to the arraylist "completionItemsArr" in TopLevelScope.java file. ( /vscode-plugin/src/main/java/org/wso2/integration/scopeprovider/TopLevelScope )

5 . Build the vscode-plugin module with "mvn clean install".


##### Deploying the snippet in Dev Mode

1 . Build Ballerina lang repo using the following command.
```groovy
./gradlew clean build -x test -x check --refresh-dependencies
```

2 . Copy the jballerina-tools-0.992.0-m2-SNAPSHOT.zip file inside ballerinaLangRepo/ballerina-lang/distribution/zip/jballerina-tools/build/distributions to a desired location and extract it.

3 . Get the jar you got from the previous steps and put it into <Extracted_Folder>/lib/tools/lang-server/lib folder

4 . Open the module "vscode" in /ballerinaLangRepo/ballerina-lang/tool-plugins/vscode  using vscode IDE.

5 . Do the following changes.<br/>
    Make "LSDEBUG": "true" in the extension element in .vscode/launch.json file.<br/>

   ```ballerina
     {
        "name": "Extension",
        "type": "extensionHost",
        "request": "launch",
        "runtimeExecutable": "${execPath}",
        "args": [
            "--extensionDevelopmentPath=${workspaceFolder}"
        ],
        "env": {
            "LS_CUSTOM_CLASSPATH": "",
            "LSDEBUG": "true",
            "COMPOSER_DEBUG": "false",
            "COMPOSER_DEV_HOST": "http://localhost:9000"
        },
        "outFiles": [
            "${workspaceFolder}/dist/**/*.js"
        ],
        "preLaunchTask": "npm: watch"
    }
    
   ```
  
  In settings.json file set ballerina.home to the location of your JBallerinaTools folder .<br/> 
     
  ```ballerina
    
    "ballerina.plugin.dev.mod":false,
    "ballerina.debugLog": true,
    "ballerina.allowExperimental": true,
    "ballerina.home": "/Users/nipuni/Downloads/jballerina-0.992.0-m2-SNAPSHOT"
```

 6 . Uninstall Ballerina VsCode plugin extension if you have already installed it.
 
 7 . Run the extension by selecting Start With Debugging in the VsCode IDE.
 
 8 . Once the Extension Development Host is started, open a .bal file.
 
 9 . Go to the Ballerina Integrator Code and start debugging.
 
 10 . Then you can see the added snippet by pressing ctrl + space keys together.
 
 
 ##### Deploying the snippet in Non-Dev Mode
 
1 . Get the jar you got from the previous steps and put it into <Ballerina_Home>/lib/tools/lang-server/lib folder

2 . Open the module "vscode" in /ballerinaLangRepo/ballerina-lang/tool-plugins/vscode  using vscode IDE.

3 . In settings.json file set ballerina.home to the location of your Ballerina_Home.<br/>  
  ```ballerina
    
    "ballerina.plugin.dev.mod":false,
    "ballerina.debugLog": true,
    "ballerina.allowExperimental": true,
    "ballerina.home": "/Users/nipuni/Downloads/jballerina-0.992.0-m2-SNAPSHOT"
```

4 . When you open a .bal file in VSCode IDE and pressed ctrl + space keys together you can see the added snippets.
