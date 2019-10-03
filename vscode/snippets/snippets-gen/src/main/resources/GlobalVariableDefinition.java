package org.wso2.integration.ballerina.autogen;

import org.antlr.v4.runtime.CommonToken;
import org.ballerinalang.annotation.JavaSPIService;
import org.ballerinalang.langserver.common.CommonKeys;
import org.ballerinalang.langserver.compiler.LSContext;
import org.ballerinalang.langserver.completions.CompletionKeys;
import org.ballerinalang.langserver.completions.SymbolInfo;
import org.ballerinalang.langserver.completions.providers.contextproviders.GlobalVarDefContextProvider;
import org.eclipse.lsp4j.CompletionItem;
import org.wso2.ballerinalang.compiler.parser.antlr4.BallerinaParser;

import java.util.ArrayList;
import java.util.List;

@JavaSPIService("org.ballerinalang.langserver.completions.spi.LSCompletionProvider")
public class GlobalVariableDefinition extends GlobalVarDefContextProvider {

    public Precedence precedence;

    public GlobalVariableDefinition() {

        this.attachmentPoints.add(BallerinaParser.GlobalVariableDefinitionContext.class);
        this.precedence = Precedence.HIGH;
    }

    @Override
    public List<CompletionItem> getCompletions(LSContext ctx) {

        List<CompletionItem> completionItems = super.getCompletions(ctx);
        List<CommonToken> lhsDefaultTokens = ctx.get(CompletionKeys.LHS_DEFAULT_TOKENS_KEY);

        if (lhsDefaultTokens.size() <= 2) {
            completionItems.addAll(this.getAllTopLevelItems(ctx));
        }
        return completionItems;
    }

    private List<CompletionItem> getAllTopLevelItems(LSContext ctx) {

        ArrayList<CompletionItem> completionItems = new ArrayList<>();
        List<SymbolInfo> visibleSymbols = new ArrayList<>(ctx.get(CommonKeys.VISIBLE_SYMBOLS_KEY));
        completionItems.addAll(TopLevelScope.addTopLevelItem(ctx));
        completionItems.addAll(this.getBasicTypes(visibleSymbols));

        return completionItems;
    }

    @Override
    public Precedence getPrecedence() {

        return this.precedence;
    }
}
