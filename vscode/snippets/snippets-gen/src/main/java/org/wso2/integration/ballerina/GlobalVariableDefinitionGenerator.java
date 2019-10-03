/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
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
 * Create Global variables to add context awareness .
 */
public class GlobalVariableDefinitionGenerator {

    private GlobalVariableDefinitionGenerator() {}
    private static final Logger log = LoggerFactory.getLogger(GlobalVariableDefinitionGenerator.class);

    static void generateGlobalVariableDefinition() throws IOException {

        String scopeBody = "";
        String scopeLine;

        File sourceFile = Paths.get("vscode", "snippets", "ei-snippets", "src", "main", "java", "org",
                "wso2", "integration", "ballerina", "autogen", "GlobalVariableDefinition.java").toFile();
        try {
            if (sourceFile.createNewFile()) {
                log.info("Successfully created TopLevelScop.java file");
            }
        } catch (IOException e) {
            String message = "Error while generating TopLevelScope.java file.";
            log.error(message, e);
        }

        String globalVariableDefinition = "package org.wso2.integration.ballerina.autogen;\n \n" +
                "import org.antlr.v4.runtime.CommonToken;\n" +
                "import org.ballerinalang.annotation.JavaSPIService;\n" +
                "import org.ballerinalang.langserver.common.CommonKeys;\n" +
                "import org.ballerinalang.langserver.compiler.LSContext;\n" +
                "import org.ballerinalang.langserver.completions.CompletionKeys;\n" +
                "import org.ballerinalang.langserver.completions.SymbolInfo;\n" +
                "import org.ballerinalang.langserver.completions.providers.contextproviders." +
                "GlobalVarDefContextProvider;\n" +
                "import org.eclipse.lsp4j.CompletionItem;\n" +
                "import org.wso2.ballerinalang.compiler.parser.antlr4.BallerinaParser;\n \n" +
                "import java.util.ArrayList;\n" +
                "import java.util.List;\n \n" +
                "@JavaSPIService(\"org.ballerinalang.langserver.completions.spi.LSCompletionProvider\")\n" +
                "public class GlobalVariableDefinition extends GlobalVarDefContextProvider {\n" +
                " public Precedence precedence;\n \n" +
                " public GlobalVariableDefinition() {\n" +
                " this.attachmentPoints.add(BallerinaParser.GlobalVariableDefinitionContext.class);\n" +
                " this.precedence = Precedence.HIGH;\n }\n @Override\n" +
                " public List<CompletionItem> getCompletions(LSContext ctx) {\n \n" +
                " List<CompletionItem> completionItems = super.getCompletions(ctx);\n" +
                " List<CommonToken> lhsDefaultTokens = ctx.get(CompletionKeys.LHS_DEFAULT_TOKENS_KEY);\n \n" +
                " if (lhsDefaultTokens.size() <= 2) {\n" +
                " completionItems.addAll(this.getAllTopLevelItems(ctx));\n }\n return completionItems;\n" +
                " }\n \n" +
                " private List<CompletionItem> getAllTopLevelItems(LSContext ctx) {\n" +
                " ArrayList<CompletionItem> completionItems = new ArrayList<>();\n" +
                " List<SymbolInfo> visibleSymbols = " +
                "new ArrayList<>(ctx.get(CommonKeys.VISIBLE_SYMBOLS_KEY)); \n" +
                "completionItems.addAll(TopLevelScope.addTopLevelItem(ctx));\n" +
                "completionItems.addAll(this.getBasicTypes(visibleSymbols));\n \n" +
                " return completionItems;\n }\n \n @Override\n public Precedence getPrecedence() {\n \n" +
                "  return this.precedence;\n }\n }";

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(globalVariableDefinition);
        writer.close();
    }
}
