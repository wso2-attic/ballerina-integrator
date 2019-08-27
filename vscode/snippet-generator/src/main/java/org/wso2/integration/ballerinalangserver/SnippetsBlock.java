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

package org.wso2.integration.ballerinalangserver;

import org.wso2.integration.util.CommonUtils;

import org.apache.commons.lang3.tuple.Pair;
import org.ballerinalang.langserver.compiler.LSContext;
import org.eclipse.lsp4j.CompletionItem;
import org.eclipse.lsp4j.CompletionItemKind;
import org.eclipse.lsp4j.TextEdit;

import java.util.ArrayList;
import java.util.List;

public class SnippetsBlock {
    private String label = "";
    private String detail = "";
    private String snippet;
    private SnippetType snippetType;
    private final Pair<String, String>[] imports;

    public SnippetsBlock(String snippet, SnippetsBlock.SnippetType snippetType) {
        this.snippet = snippet;
        this.snippetType = snippetType;
        this.imports = null;
    }

    public SnippetsBlock(String label, String snippet, String detail, SnippetsBlock.SnippetType snippetType) {
        this.label = label;
        this.snippet = snippet;
        this.detail = detail;
        this.snippetType = snippetType;
        this.imports = null;
    }

    public SnippetsBlock(String label, String snippet, String detail, SnippetsBlock.SnippetType snippetType,
                        Pair<String, String>... importsByOrgAndAlias) {
        this.label = label;
        this.snippet = snippet;
        this.detail = detail;
        this.snippetType = snippetType;
        this.imports = importsByOrgAndAlias;
    }

    /**
     * Create a given completionItem's insert text.
     *
     * @param ctx   LS Context
     * @return modified Completion Item
     */
      public CompletionItem build(LSContext ctx) {
        CompletionItem completionItem = new CompletionItem();
        completionItem.setInsertText(this.snippet);
        if (imports != null) {
            List<TextEdit> importTextEdits = new ArrayList<>();
            for (Pair<String, String> pair : imports) {
                importTextEdits.addAll(CommonUtils.getAutoImportTextEdits( pair.getLeft(), pair.getRight(),ctx));
            }
            completionItem.setAdditionalTextEdits(importTextEdits);
        }
        if (!label.isEmpty()) {
            completionItem.setLabel(label);
        }
        if (!detail.isEmpty()) {
            completionItem.setDetail(detail);
        }
        completionItem.setKind(getKind());
        return completionItem;
    }

    /**
     * Get the Snippet String.
     *
     * @return {@link String}
     */
    public String getString() {
        return this.snippet;
    }

    /**
     * Returns LSP Snippet Type.
     *
     * @return {@link CompletionItemKind} LSP Snippet Type
     */
    private CompletionItemKind getKind() {
        switch (snippetType) {
            case KEYWORD:
                return CompletionItemKind.Keyword;
            case SNIPPET:
            case STATEMENT:
                return CompletionItemKind.Snippet;
            default:
                return CompletionItemKind.Snippet;
        }
    }

    public String getLabel() {
        return label;
    }

    /**
     * Represents Snippet Types in B7a LS.
     */
    public enum SnippetType {
        KEYWORD, SNIPPET, STATEMENT;
    }
}
