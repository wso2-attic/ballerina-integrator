// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package org.wso2.integration.ballerina;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.wso2.integration.ballerina.ItemResolverConstantsGenerator.generateItemResolverConstants;
import static org.wso2.integration.ballerina.SnippetsContentGenerator.generateSnippetContent;
import static org.wso2.integration.ballerina.SnippetsDefinitionGenerator.generateSnippetDefinition;
import static org.wso2.integration.ballerina.TopLevelScopeGenerator.generateTopLevelScope;

class SnippetGenerator {

    // private static Logger log = LoggerFactory.getLogger(SnippetGenerator.class);


    public static void main(String[] args) {
        processSnippet();

    }

    private static List<File> readFiles() throws FileNotFoundException {
        File files = Paths.get("vscode", "snippets", "snippets-gen", "src", "main", "resources", "Snippets").toFile();
        if (files.listFiles() == null) {
            throw new FileNotFoundException("No files in the given location: ");
        }
        return new ArrayList<>(Arrays.asList(files.listFiles()));


    }

    static void processSnippet() {
        List<File> fileList = new ArrayList<>();
        try {
            fileList = readFiles();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        String sCurrentLine;
        List<String> snippetArr = new ArrayList<>();
        List<String> nameArr = new ArrayList<>();
        List<String> triggerArr = new ArrayList<>();
        List<String> importsArr = new ArrayList<>();

        for (File file : fileList) {
            try (BufferedReader reader = Files.newBufferedReader(Paths.get(String.valueOf(file)))) {
                while ((sCurrentLine = reader.readLine()) != null) {
                    if (sCurrentLine.trim().length() != 0) {
                        if (sCurrentLine.contains("Name ")) {
                            nameArr.add(sCurrentLine);
                        }
                        if (sCurrentLine.contains("Trigger ")) {
                            triggerArr.add(sCurrentLine);
                        }
                        if (sCurrentLine.contains("Imports ")) {
                            importsArr.add(sCurrentLine);
                        }


                    } else {
                        String snippet = readSnippet(reader);
                        snippetArr.add(snippet);
                    }
                }

            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        System.out.println("Snippet Array list ---->" + snippetArr.size());
        System.out.println("Name list ---->" + nameArr.size());
        System.out.println("Trigger list ---->" + triggerArr.size());
        System.out.println("Imports Array list ---->" + importsArr.size());
        try {
            generateItemResolverConstants(nameArr, triggerArr);
            generateTopLevelScope(nameArr);
            generateSnippetDefinition(nameArr);
            generateSnippetContent(nameArr,importsArr,snippetArr);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    private static String readSnippet(BufferedReader reader) throws IOException {
        int consecutiveEmptyLineCounter = 0;
        String currentLine = "";
        String snippetContent = "";


        while ((currentLine = reader.readLine()) != null) {

            if (currentLine.trim().length() != 0) {
                snippetContent = snippetContent + "\\n" + currentLine;

            } else {
                consecutiveEmptyLineCounter++;
            }
        }

        return snippetContent;
    }


}