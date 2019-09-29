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

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.List;

public class SnippetsContentGenerator {
    public SnippetsContentGenerator() {
    }

    static void generateSnippetContent(List<String> names, List<String> imports, List<String> snippets) throws IOException {
        String snippetLine = "";
        String scopeLine = "";
        String snippetBody = "";
        String snippetFooter = "";

        File sourceFile = Paths.get("vscode", "snippets", "ei-snippets", "src", "main", "java", "org",
                                    "wso2", "integration", "ballerina", "autogen", "SnippetsContent.java").toFile();

        try {
            sourceFile.createNewFile();
        } catch (IOException e) {
            e.printStackTrace();
        }

        String snippetContentHeder =  "package org.wso2.integration.ballerina.autogen;\n" + "\n" +
                                      "import org.apache.commons.lang3.tuple.ImmutablePair;\n" +
                                      "import org.wso2.integration.ballerina.util.SnippetsBlock;\n" +
                                      "import org.ballerinalang.langserver.common.utils.CommonUtil;\n" +
                                                                                               "\n" + "\n" + "\n" +
                                      "public class SnippetsContent {\n" + "\n" +
                                                                      "    private SnippetsContent() {\n" + "    } " + "\n";

        for (int i = 0 ;i < snippets.size() ; i++) {
            String[] namesParts = names.get(i).split(":");
           // String importNames =  ;
            String[] namesSplit = names.get(i).split(":");
            snippetLine =  "public static SnippetsBlock get" + namesSplit[1].trim() + "snippet {" + "\n" + getImports(imports);
            snippetBody = "\n" + "String snippet = " + "\"" +snippets.get(i) + "\"" + ";";

            snippetFooter = "return new SnippetsBlock(ItemResolverConstants." + namesParts[1].trim().toUpperCase() + "ItemResolverConstants.SNIPPET_TYPE,"
                             +    "SnippetsBlock.SnippetType.SNIPPET," ;
        }

         String snippetContent = snippetContentHeder + snippetLine + snippetBody + snippetFooter ;

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(snippetContent);
        writer.close();

    }

    static String getImports(List<String> imports) {
        String[] splitImports = {};
        String[] importsArr = {};
        String immutablePairs = "";
        for (int i = 0; i < imports.size(); i++) {
            splitImports = imports.get(i).split(",");
        }

        for (int j = 0; j < splitImports.length; j++) {
            importsArr = splitImports[j].split("/");

        }

        for (int k = 0; k < splitImports.length; k++) {
            String[] pair = splitImports[k].split("/");
            if(pair[0].contains(":") ){
                String[] keys = pair[0].split(":");
                pair[0] = keys[1];
            }
          
            immutablePairs = immutablePairs + "\n" + "\t" + "ImmutablePair<String, String> imports" + k +
                                  " = new ImmutablePair<> (" + "\"" + pair[0] + "\"" + "," +  "\"" + pair[1] + "\""
                                                                               +    " )" + ";";
        }

        return immutablePairs;

        }
    }
