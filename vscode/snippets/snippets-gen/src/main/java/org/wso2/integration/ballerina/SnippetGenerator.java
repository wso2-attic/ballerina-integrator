/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

package org.wso2.integration.ballerina;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Main method executed for the auto generation of files to create the snippet.
 */
class SnippetGenerator {

    private static final Logger log = LoggerFactory.getLogger(SnippetGenerator.class);

    public static void main(String[] args) throws Exception {

        List<File> fileList = readSnippetTextFiles();
        List<Snippet> snippetList = processSnippet(fileList);
        genearteJavaCode(snippetList);
    }

    private static List<File> readSnippetTextFiles() throws IOException {

        File files = Paths.get("vscode","snippets","snippets-gen","src", "main", "resources", "snippet-files").toFile();

        if (files.listFiles().length != 0) {
            return new ArrayList<>(Arrays.asList(files.listFiles()));
        } else {
            log.debug("No files are found in the given location");
            throw new IOException("Error in reading files");
        }
    }

    private static List<Snippet> processSnippet(List<File> fileList) throws IOException {

        String currentLine;
        List<Snippet> snippetList = new ArrayList<>();

        for (File file : fileList) {
            Snippet snippet = new Snippet();
            try (BufferedReader reader = Files.newBufferedReader(Paths.get(String.valueOf(file)))) {

                while ((currentLine = reader.readLine()) != null) {
                    if (currentLine.trim().length() != 0) {
                        if (currentLine.contains("Name ")) {
                            snippet.setName(currentLine);
                        }
                        if (currentLine.contains("Trigger ")) {
                            snippet.setTrigger(currentLine);
                        }
                        if (currentLine.contains("Imports ")) {
                            snippet.setImports(currentLine);
                        }
                    } else {
                        String snippets = readSnippet(reader);
                        snippet.setCode(snippets);
                    }
                }
                if (null != snippet.getName() && !snippet.getName().isEmpty()) {
                    snippetList.add(snippet);
                }
            } catch (IOException e) {
                String message = "Error while reading file content.";
                log.error(message, e);
                throw new IOException(message, e);
            }
        }
        return snippetList;
    }

    private static String readSnippet(BufferedReader reader) throws IOException {

        int consecutiveEmptyLineCounter = 0;
        String currentLine;
        String snippetContent = "";

        while ((currentLine = reader.readLine()) != null) {
            StringBuilder stringBuilder = new StringBuilder();
            if (currentLine.trim().length() != 0) {
                snippetContent = stringBuilder.append(snippetContent).append("\\n").append(currentLine).toString();
            } else {
                consecutiveEmptyLineCounter++;
                if (consecutiveEmptyLineCounter > 3) {
                    String message = "Error occured due to excess empty lines.";
                    log.error(message);
                }
            }
        }
        return snippetContent;
    }

    private static void genearteJavaCode(List<Snippet> snippetList) throws IOException {

        ItemResolverConstantsGenerator.generateItemResolverConstants(snippetList);
        SnippetsContentGenerator.generateSnippetContent(snippetList);
        SnippetsDefinitionGenerator.generateSnippetDefinition(snippetList);
        TopLevelScopeGenerator.generateTopLevelScope(snippetList);

        log.info("Files generated successfully");
    }
}
