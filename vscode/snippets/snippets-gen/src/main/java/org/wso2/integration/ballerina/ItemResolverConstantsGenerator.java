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

class ItemResolverConstantsGenerator {
    private ItemResolverConstantsGenerator() {

    }

     static void generateItemResolverConstants(List<String> names, List<String> trigger) throws IOException {
        String snippetBody = "";
        String snippetLine;

        File sourceFile = Paths.get("vscode", "snippets", "ei-snippets", "src", "main", "java", "org",
                                    "wso2", "integration", "ballerina", "autogen", "ItemResolverConstants.java").
                                                                                                            toFile();


        try {
            sourceFile.createNewFile();
        } catch (IOException e) {
            e.printStackTrace();
        }

        String snippetHeader = "package org.wso2.integration.ballerina.autogen;" + "\n" + "\n" +
                               "public class ItemResolverConstants" + "{ " + "\n" + "\n";


        for (int i = 0; i < names.size(); i++) {
            String[] namesParts = names.get(i).split(":");
            String[] triggerParts = trigger.get(i).split(":");
            snippetLine = "public static final String" + namesParts[1].toUpperCase() + " =" + "\"" + triggerParts[1].trim() +
                                                                                            "\"" + ";" + "\n";
            snippetBody = snippetBody + snippetLine;
        }

        String itemResolver = snippetHeader + snippetBody + "\n" + "\n" + "}";

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(itemResolver);
        writer.close();

    }

}


