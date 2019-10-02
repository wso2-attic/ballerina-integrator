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

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.List;

import javafx.util.Pair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Genearates the content of the snippet.
 */
class SnippetsContentGenerator {

    private SnippetsContentGenerator() {}

    private static final Logger log = LoggerFactory.getLogger(SnippetsContentGenerator.class);

    static void generateSnippetContent(List<Snippet> snippetList) throws IOException {

        String snippetLine;
        String snippetBody;
        String snippetFooter;

        File sourceFile = Paths.get("vscode","snippets","ei-snippets", "src", "main", "java", "org",
                "wso2", "integration", "ballerina", "autogen", "SnippetsContent.java").toFile();

        try {
            if (sourceFile.createNewFile()) {
                log.info("Successfully created ItemResolverConstants.java file");
            }
        } catch (IOException e) {
             String message = "Error while generating SnippetsContent.java file.";
             log.error(message, e);
        }

        String snippetContentHeder =  "package org.wso2.integration.ballerina.autogen;\n\n" +
                                      "import org.apache.commons.lang3.tuple.ImmutablePair;\n" +
                                      "import org.ballerinalang.langserver.SnippetBlock;\n\n\n" +
                                      "public class SnippetsContent {\n\n" +
                                      "   private SnippetsContent() { \n } \n";

        String snippetContent = "";

        for (Snippet snippetObject : snippetList) {
            StringBuilder stringBuilder = new StringBuilder();
            Pair<String, String> pair = getImportText(snippetObject);

            String[] namesParts = snippetObject.getName().split(":");

            snippetLine = "\n public static SnippetBlock get" + namesParts[1].trim().
                    replaceAll("_", "") + "() { \n" + pair.getKey();
            String generated = snippetObject.getCode().replaceAll("\"", "\\\\\"");

            snippetBody = "\n \n String snippet =\"" + generated + "\" ;";
            snippetFooter = "\n \nreturn new SnippetBlock(ItemResolverConstants." + namesParts[1].trim().
                    toUpperCase() + ", snippet,ItemResolverConstants.SNIPPET_TYPE," +
                    "SnippetBlock.SnippetType.SNIPPET," + pair.getValue() + "); \n }";
            snippetContent = stringBuilder.append(snippetContent).append(snippetLine).append(snippetBody).
                    append(snippetFooter).append("\n").toString();
        }

        String finalSnippet = snippetContentHeder + snippetContent + "}";

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(finalSnippet);
        writer.close();
    }

    private static Pair<String, String> getImportText(Snippet snippet) {

        String[] splitImports;
        String immutablePairs = "";
        String importsList = "";

        String imports = snippet.getImports();
        splitImports = imports.split(",");

        for (int i = 0; i < splitImports.length; i++) {
            StringBuilder stringBuilder = new StringBuilder();
            String[] pair = splitImports[i].split("/");

            if (pair[0].contains(":")) {
                String[] keys = pair[0].split(":");
                pair[0] = keys[1];
            }

            immutablePairs = stringBuilder.append(immutablePairs).append("\n").append("\t").
                    append("ImmutablePair<String, String> imports").append(i).
                    append("= new ImmutablePair<> (").append("\"").append(pair[0].trim()).
                    append("\"").append(",").append("\"".trim()).append(pair[1]).append("\"").
                    append(" )").append(";").toString();

            importsList = "imports" + i;
        }
        return new Pair<>(immutablePairs, importsList);
    }
}
