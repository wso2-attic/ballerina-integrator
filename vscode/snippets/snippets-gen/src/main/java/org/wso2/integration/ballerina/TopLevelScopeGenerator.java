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
 * Contains methods required to display the Top Level Scope snippets  .
 */
class TopLevelScopeGenerator {

    private TopLevelScopeGenerator() {}

    private static final Logger log = LoggerFactory.getLogger(SnippetGenerator.class);

    static void generateTopLevelScope(List<Snippet> snippetList) throws IOException {

        String scopeBody = "";
        String scopeLine;

        File sourceFile = Paths.get("vscode","snippets","ei-snippets", "src", "main", "java", "org",
                "wso2", "integration", "ballerina", "autogen", "TopLevelScope.java").toFile();

        try {
            if (sourceFile.createNewFile()) {
                log.info("Successfully created TopLevelScop.java file");
            }
        } catch (IOException e) {
            String message = "Error while generating TopLevelScope.java file.";
            log.error(message, e);
        }

        String scopeHeader = "package org.wso2.integration.ballerina.autogen;\n\n" +
                "import org.antlr.v4.runtime.CommonToken;\n"+
                "import org.ballerinalang.annotation.JavaSPIService;\n"+
                "import org.ballerinalang.langserver.compiler.LSContext;\n"+
                "import org.ballerinalang.langserver.completions.CompletionKeys;\n"+
                "import org.ballerinalang.langserver.completions.providers.scopeproviders.TopLevelScopeProvider;\n"+
                "import org.eclipse.lsp4j.CompletionItem;\n" +
                "import org.wso2.ballerinalang.compiler.tree.BLangPackage;\n" +
                "import java.util.ArrayList;\n" +
                "import java.util.List;\n"+
                "@JavaSPIService(\"org.ballerinalang.langserver.completions.spi.LSCompletionProvider\")\n" +
                "public class TopLevelScope extends TopLevelScopeProvider {\n\n  public Precedence precedence;" +
                "    public TopLevelScope() {\n this.attachmentPoints.add(BLangPackage.class); \n" +
                "        this.precedence = Precedence.HIGH;\n }\n \n /**\n" +
                "     * Get a static completion Item for the given snippet.\n *\n" +
                "     * @param snippet Snippet to generate the static completion item\n" +
                "     * @return {@link CompletionItem} Generated static completion Item\n */\n\n" +
                "    protected static CompletionItem getStaticItem(LSContext ctx, Snippets snippet) {\n" +
                "        return snippet.get().build(ctx);\n      }\n\n" +
                "    public static final LSContext.Key<List<CommonToken>> LHS_DEFAULT_TOKENS_KEY = " +
                "new LSContext.Key<>();\n" +
                " //Override the getCompletions method in LSCompletion Provider\n " +
                "@Override public List<CompletionItem> getCompletions(LSContext ctx) {\n" +
                " List<CompletionItem> completions = super.getCompletions(ctx);\n \n" +
                " if(CompletionKeys.LHS_DEFAULT_TOKENS_KEY != null) {\n \n" +
                " List<CommonToken> lhsDefaultTokens = ctx.get(CompletionKeys.LHS_DEFAULT_TOKENS_KEY);\n" +
                " if (lhsDefaultTokens == null || lhsDefaultTokens.size() == 0) {\n" +
                "  completions.addAll(addTopLevelItem(ctx));\n }\n }\n return completions;\n }"+
                "  protected static List<CompletionItem> addTopLevelItem(LSContext context) {\n" +
                "        ArrayList<CompletionItem> completionItemsArr = new ArrayList<>(); \t \n \n";

        for (Snippet snippet : snippetList) {
            StringBuilder stringBuilder = new StringBuilder();
            String[] namesSplit = snippet.getName().split(":");
            scopeLine = "\t \t completionItemsArr.add(getStaticItem(context, Snippets.DEF_" +
                    namesSplit[1].trim() + ")) ; \n";
            scopeBody = stringBuilder.append(scopeBody).append(scopeLine).toString();
        }
        String topLevelScope = scopeHeader + scopeBody + "\n \n return completionItemsArr;} \n @Override\n" +
                "   public Precedence getPrecedence() {\n \n  return this.precedence;\n  }\n }";
        FileWriter writer = new FileWriter(sourceFile);
        writer.write(topLevelScope);
        writer.close();
    }
}
