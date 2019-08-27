package org.wso2.integration.scopeprovider;

import org.wso2.integration.util.Snippets;
import org.antlr.v4.runtime.CommonToken;
import org.ballerinalang.annotation.JavaSPIService;
import org.ballerinalang.langserver.common.CommonKeys;
import org.ballerinalang.langserver.compiler.LSContext;
import org.ballerinalang.langserver.completions.SymbolInfo;
import org.ballerinalang.langserver.completions.providers.scopeproviders.TopLevelScopeProvider;
import org.ballerinalang.langserver.completions.spi.LSCompletionProvider;
import org.eclipse.lsp4j.CompletionItem;
import org.wso2.ballerinalang.compiler.parser.antlr4.BallerinaParser;
import org.wso2.ballerinalang.compiler.tree.BLangPackage;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@JavaSPIService("org.ballerinalang.langserver.completions.spi.LSCompletionProvider")
public class TopLevelScope extends TopLevelScopeProvider {

    public static Precedence precedence;

    public TopLevelScope() {
        this.attachmentPoints.add(BLangPackage.class);
        this.precedence = Precedence.HIGH;
    }

    /**
     * Get a static completion Item for the given snippet.
     *
     * @param snippet Snippet to generate the static completion item
     * @return {@link CompletionItem} Generated static completion Item
     */

    protected CompletionItem getStaticItem(LSContext ctx, Snippets snippet) {
        return snippet.get().build(ctx);
    }

    public static final LSContext.Key<List<CommonToken>> LHS_DEFAULT_TOKENS_KEY = new LSContext.Key<>();


    //Override the getCompletions method in LSCompletion Provider
    @Override
    public List<CompletionItem> getCompletions(LSContext ctx) {
         ArrayList<CompletionItem> completionItm = new ArrayList<>();
        Optional<LSCompletionProvider> contextProvdr = this.getContextProvider(ctx);
        List<CommonToken> lhsDefaultTokens = ctx.get(LHS_DEFAULT_TOKENS_KEY);

        if (contextProvdr.isPresent()) {
            return contextProvdr.get().getCompletions(ctx);
        }

        if (!(lhsDefaultTokens != null && lhsDefaultTokens.size() >= 2 && BallerinaParser.LT == lhsDefaultTokens
                                                                      .get(lhsDefaultTokens.size() - 1).getType())) {
            completionItm.addAll(addTopLevelItem(ctx));
        }
        List<SymbolInfo> visibleSymbols = new ArrayList<>(ctx.get(CommonKeys.VISIBLE_SYMBOLS_KEY));
        completionItm.addAll((Collection<? extends CompletionItem>) getBasicTypes(visibleSymbols));
        completionItm.addAll((Collection<? extends CompletionItem>) this.getPackagesCompletionItems(ctx));

        return completionItm;
    }


    protected List<CompletionItem> addTopLevelItem(LSContext context) {
        ArrayList<CompletionItem> completionItemsArr = new ArrayList<>();

        completionItemsArr.add(getStaticItem(context, Snippets.DEF_SERVICE_GRPC));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_HTTP));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RECORD));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_SERVICE_WEBSOCKET));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_SERVICE_AMAZONS3));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_CREATE_BUCKET));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_CLIENT_CONFIG_AMAZONS3));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_CLIENT_AMAZONS3));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_ERROR_HANDLING));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_LIST_BUCKETS));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_CREATE_OBJECT));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_GET_OBJECT));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_LIST_OBJECTS));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_DELETE_OBJECT));
        completionItemsArr.add(getStaticItem(context, Snippets.DEF_RESOURCE_S3_DELETE_BUCKET));

        return completionItemsArr;
    }
}
