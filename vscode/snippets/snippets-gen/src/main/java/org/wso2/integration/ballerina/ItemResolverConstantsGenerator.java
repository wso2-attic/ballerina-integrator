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
 * Genearates the snippet display labels.
 */
class ItemResolverConstantsGenerator {

    private ItemResolverConstantsGenerator() {}

    private static final Logger log = LoggerFactory.getLogger(ItemResolverConstantsGenerator.class);

    static void generateItemResolverConstants(List<Snippet> snippetList) throws IOException {

        String snippetBody = "";
        String snippetLine;

        File sourceFile = Paths.get("vscode","snippets","ei-snippets", "src", "main", "java", "org",
                "wso2", "integration", "ballerina", "autogen", "ItemResolverConstants.java").toFile();

        try {
            if (sourceFile.createNewFile()) {
                log.info("Successfully created ItemResolverConstants.java file");
            }
        } catch (IOException e) {
            String message = "Error while generating ItemResolverConstants.java file.";
            log.error(message, e);
        }

        String snippetHeader = "package org.wso2.integration.ballerina.autogen;\n\n" +
                               "public class ItemResolverConstants { \n \n // Symbol Types Constants\n" +
                               "    public static final String SNIPPET_TYPE = \"Snippet\";\n" +
                               "    public static final String RESOURCE = \"resource\";\n" +
                               "    public static final String RECORD_TYPE = \"type <RecordName> record\";\n" +
                               "    // End Symbol Types Constants \n";

        for (Snippet snippet : snippetList) {
            StringBuilder sb = new StringBuilder();
            String name = snippet.getName();
            String trigger = snippet.getTrigger();
            String[] namesParts = name.split(":");
            String[] triggerParts = trigger.split(":");

            snippetLine = "\t" + "public static final String" + namesParts[1].toUpperCase() + " =" + "\"" +
                    triggerParts[1].trim() + "\"" + ";" + "\n";
            snippetBody = sb.append(snippetBody).append(snippetLine).toString();
        }

        String itemResolver = snippetHeader + snippetBody + "\n \n" + "}";
        FileWriter writer = new FileWriter(sourceFile);
        writer.write(itemResolver);
        writer.close();
    }
}
