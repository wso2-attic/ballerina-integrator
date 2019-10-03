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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Genearates the snippet definition.
 */
class SnippetsDefinitionGenerator {

    private SnippetsDefinitionGenerator() {}

    private static final Logger log = LoggerFactory.getLogger(SnippetsDefinitionGenerator.class);

    static void generateSnippetDefinition(List<Snippet> snippetList) throws IOException {

        String snippetDefBody = "";

        File sourceFile = Paths.get("vscode","snippets","ei-snippets", "src", "main", "java", "org",
                "wso2", "integration", "ballerina", "autogen", "Snippets.java").toFile();
        try {
            if (sourceFile.createNewFile()) {
                log.info("Successfully created ItemResolverConstants.java file");
            }
        } catch (IOException e) {
            String message = "Error while generating Snippets.java file.";
            log.error(message, e);
        }

        String snippetDefHeader = "package org.wso2.integration.ballerina.autogen;\n \n \n" +
                                  "import org.ballerinalang.langserver.SnippetBlock;\n/**\n"  +
                                  "* Snippets for the Ballerina Integrator.\n */\n \n" +
                                  "public enum Snippets {\n \n";

        String snippetDefFooter = "\n private String snippetName;\n" +
                                  " \n private SnippetBlock snippetBlock;\n \n" +
                                  "   Snippets(SnippetBlock snippetBlock) {\n" +
                                  "   this.snippetName = null;\n" +
                                  "this.snippetBlock = snippetBlock;\n" +
                                  "    }\n \n " +
                                  "  Snippets(String snippetName, SnippetBlock snippetBlock) {\n" +
                                  "  this.snippetName = snippetName;\n" +
                                  "  this.snippetBlock = snippetBlock;\n }\n \n  /**\n" +
                                  "  * Get the Snippet Name.\n *\n" +
                                  "     * @return {@link String} snippet name\n" +
                                  "  */\n public String snippetName() {\n" +
                                  "   return this.snippetName;\n   }\n \n /**\n" +
                                  "     * Get the SnippetBlock.\n  *\n" +
                                  "     * @return {@link SnippetBlock} SnippetBlock\n */\n" +
                                  "    public SnippetBlock get() {\n return this.snippetBlock;\n }\n }";

        for (int i = 0; i < snippetList.size(); i++) {
            StringBuilder stringBuilder = new StringBuilder();
            String[] namesSplit = snippetList.get(i).getName().trim().split(":");
            String name = namesSplit[1].trim();
            String snippetDefPart = "DEF_" + name + "(SnippetsContent.get" + name.replaceAll("_", "")
                    + "())";
            if (i < (snippetList.size() - 1)) {
                snippetDefBody = stringBuilder.append(snippetDefBody).append(snippetDefPart).append(",").append("\n").
                        toString();
            } else {
                snippetDefBody = stringBuilder.append(snippetDefBody).append(snippetDefPart).append(";").append("\n").
                        toString();
            }
        }
        String snippetDefinition = snippetDefHeader + snippetDefBody + snippetDefFooter;

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(snippetDefinition);
        writer.close();
    }
}
