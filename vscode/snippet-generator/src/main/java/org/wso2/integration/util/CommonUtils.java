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

package org.wso2.integration.util;

import org.antlr.v4.runtime.CommonToken;
import org.apache.commons.lang3.StringUtils;
import org.ballerinalang.langserver.common.CommonKeys;
import org.ballerinalang.langserver.compiler.LSContext;
import org.ballerinalang.langserver.completions.util.ItemResolverConstants;
import org.ballerinalang.langserver.index.dto.BPackageSymbolDTO;
import org.ballerinalang.model.elements.PackageID;
import org.ballerinalang.model.symbols.SymbolKind;
import org.ballerinalang.model.types.ConstrainedType;
import org.ballerinalang.util.BLangConstants;
import org.eclipse.lsp4j.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.ballerinalang.compiler.semantics.model.symbols.BAnnotationSymbol;
import org.wso2.ballerinalang.compiler.semantics.model.symbols.BInvokableSymbol;
import org.wso2.ballerinalang.compiler.semantics.model.symbols.BSymbol;
import org.wso2.ballerinalang.compiler.semantics.model.types.*;
import org.wso2.ballerinalang.compiler.tree.BLangImportPackage;
import org.wso2.ballerinalang.compiler.tree.BLangNode;
import org.wso2.ballerinalang.compiler.tree.BLangPackage;
import org.wso2.ballerinalang.compiler.tree.expressions.BLangExpression;
import org.wso2.ballerinalang.compiler.tree.expressions.BLangInvocation;
import org.wso2.ballerinalang.compiler.tree.statements.BLangSimpleVariableDef;
import org.wso2.ballerinalang.compiler.util.Name;
import org.wso2.ballerinalang.util.Flags;

import java.io.File;
import java.util.*;
import java.util.function.BiFunction;
import java.util.stream.Collectors;

public class CommonUtils {

    private static final Logger logger = LoggerFactory.getLogger(CommonUtils.class);

    public static final String MD_LINE_SEPARATOR = "  " + System.lineSeparator();

    public static final String LINE_SEPARATOR = System.lineSeparator();

    public static final String FILE_SEPARATOR = File.separator;

    public static final String LINE_SEPARATOR_SPLIT = "\\r?\\n";

    public static final boolean LS_DEBUG_ENABLED;

    public static final String BALLERINA_HOME;

    public static final String MARKDOWN_MARKUP_KIND = "markdown";

    static {
        String debugLogStr = System.getProperty("ballerina.debugLog");
        LS_DEBUG_ENABLED = Boolean.parseBoolean(debugLogStr);
        BALLERINA_HOME = System.getProperty("ballerina.home");
    }

    private CommonUtils() {
    }

    /**
     * Get the Annotation completion Item.
     *
     * @param packageID        Package Id
     * @param annotationSymbol BLang annotation to extract the completion Item
     * @param ctx              LS Service operation context, in this case completion context
     * @param pkgAlias         LS Service operation context, in this case completion context
     * @return {@link CompletionItem} Completion item for the annotation
     */
    public static CompletionItem getAnnotationCompletionItem(PackageID packageID, BAnnotationSymbol annotationSymbol,
                                                             LSContext ctx, CommonToken pkgAlias,
                                                             Map<String, String> pkgAliasMap) {
        PackageID currentPkgID = ctx.get(ServiceKeys.CURRENT_PACKAGE_ID_KEY);

        String aliasComponent = "";
        if (pkgAliasMap.containsKey(packageID.toString())) {
            // Check if the imported packages contains the particular package with the alias
            aliasComponent = pkgAliasMap.get(packageID.toString());
        } else if (!currentPkgID.name.value.equals(packageID.name.value)) {
            aliasComponent = CommonUtils.getLastItem(packageID.getNameComps()).getValue();
        }

        boolean withAlias = (pkgAlias == null && !aliasComponent.isEmpty());

        String label = getAnnotationLabel(aliasComponent, annotationSymbol, withAlias);
        String insertText = getAnnotationInsertText(aliasComponent, annotationSymbol, withAlias);
        CompletionItem annotationItem = new CompletionItem();
        annotationItem.setLabel(label);
        annotationItem.setInsertText(insertText);
        annotationItem.setInsertTextFormat(InsertTextFormat.Snippet);
        annotationItem.setDetail(ItemResolverConstants.ANNOTATION_TYPE);
        annotationItem.setKind(CompletionItemKind.Property);
        if (currentPkgID.name.value.equals(packageID.name.value)) {
            // If the annotation resides within the current package, no need to set the additional text edits
            return annotationItem;
        }
        List<BLangImportPackage> imports = CommonUtils.getCurrentModuleImports(ctx);
        Optional currentPkgImport = imports.stream().filter(bLangImportPackage -> {
            String pkgName = bLangImportPackage.orgName + "/" + CommonUtils.getPackageNameComponentsCombined
                                                                                                 (bLangImportPackage);
            String evalPkgName = packageID.orgName + "/" + packageID.nameComps.stream().map(Name::getValue).
                                                                             collect(Collectors.joining("."));
            return pkgName.equals(evalPkgName);
        }).findAny();
        // if the particular import statement not available we add the additional text edit to auto import
        if (!currentPkgImport.isPresent()) {
            annotationItem.setAdditionalTextEdits(getAutoImportTextEdits(packageID.orgName.getValue(),
                                                                         packageID.name.getValue(), ctx));
        }
        return annotationItem;
    }


    /**
     * Get the text edit for an auto import statement.
     * Here we do not check whether the package is not already imported. Particular check should be done before usage
     *
     * @param orgName package org name
     * @param pkgName package name
     * @param context Language server context
     * @return {@link List}     List of Text Edits to apply
     */
    public static List<TextEdit> getAutoImportTextEdits(String orgName, String pkgName, LSContext context) {
        List<BLangImportPackage> currentFileImports = context.get(ServiceKeys.CURRENT_DOC_IMPORTS_KEY);
        Position start = new Position(0, 0);
        if (currentFileImports != null && !currentFileImports.isEmpty()) {
            BLangImportPackage last = CommonUtils.getLastItem(currentFileImports);
            int endLine = last.getPosition().getEndLine();
            start = new Position(endLine, 0);
        }
        String pkgNameComponent;
        // Check for the lang lib module insert text
        if ("ballerina".equals(orgName) && pkgName.startsWith("lang.")) {
            pkgNameComponent = pkgName.replace(".", ".'");
        } else {
            pkgNameComponent = pkgName;
        }
        String importStatement = ItemResolverConstants.IMPORT + " " + orgName + CommonKeys.SLASH_KEYWORD_KEY +
                                 pkgNameComponent + CommonKeys.SEMI_COLON_SYMBOL_KEY + CommonUtils.LINE_SEPARATOR;
        return Collections.singletonList(new TextEdit(new Range(start, start), importStatement));
    }


    /**
     * Populate the given map with the completion item.
     *
     * @param map            ID to completion item map
     * @param id             pkg id in index
     * @param completionItem completion item to populate
     */
    public static void populateIdCompletionMap(HashMap<Integer, ArrayList<CompletionItem>> map, int id,
                                               CompletionItem completionItem) {
        if (map.containsKey(id)) {
            map.get(id).add(completionItem);
        } else {
            map.put(id, new ArrayList<>(Collections.singletonList(completionItem)));
        }
    }

    /**
     * Get the annotation Insert text.
     *
     * @param aliasComponent   Package ID
     * @param annotationSymbol Annotation to get the insert text
     * @param withAlias        insert text with alias
     * @return {@link String} Insert text
     */
    private static String getAnnotationInsertText(String aliasComponent, BAnnotationSymbol annotationSymbol,
                                                  boolean withAlias) {
        StringBuilder annotationStart = new StringBuilder();
        if (withAlias) {
            annotationStart.append(aliasComponent).append(CommonKeys.PKG_DELIMITER_KEYWORD);
        }
        if (annotationSymbol.attachedType != null) {
            annotationStart.append(annotationSymbol.getName().getValue()).append(" ").append(CommonKeys.OPEN_BRACE_KEY)
                           .append(LINE_SEPARATOR);
            List<BField> requiredFields = new ArrayList<>();
            if (annotationSymbol.attachedType.type instanceof BRecordType) {
                requiredFields = getRecordRequiredFields(((BRecordType) annotationSymbol.attachedType.type));
                List<String> insertTexts = new ArrayList<>();
                requiredFields.forEach(field -> {
                    String fieldInsertionText = "\t" + getRecordFieldCompletionInsertText(field, 1);
                    insertTexts.add(fieldInsertionText);
                });
                annotationStart.append(String.join("," + LINE_SEPARATOR, insertTexts));
            }
            if (requiredFields.isEmpty()) {
                annotationStart.append("\t").append("${1}").append(LINE_SEPARATOR);
            }
            annotationStart.append(CommonKeys.CLOSE_BRACE_KEY);
        } else {
            annotationStart.append(annotationSymbol.getName().getValue());
        }

        return annotationStart.toString();
    }

    /**
     * Get the completion Label for the annotation.
     *
     * @param aliasComponent package alias
     * @param annotation     BLang annotation
     * @param withAlias      label with alias
     * @return {@link String} Label string
     */
    private static String getAnnotationLabel(String aliasComponent, BAnnotationSymbol annotation, boolean withAlias) {
        String pkgComponent = withAlias ? aliasComponent + CommonKeys.PKG_DELIMITER_KEYWORD : "";
        return pkgComponent + annotation.getName().getValue();
    }

    /**
     * Get the default value for the given BType.
     *
     * @param bType BType to get the default value
     * @return {@link String}   Default value as a String
     */
    public static String getDefaultValueForType(BType bType) {
        String typeString;
        if (bType == null) {
            return "()";
        }
        switch (bType.getKind()) {
            case INT:
                typeString = Integer.toString(0);
                break;
            case FLOAT:
                typeString = Float.toString(0);
                break;
            case STRING:
                typeString = "\"\"";
                break;
            case BOOLEAN:
                typeString = Boolean.toString(false);
                break;
            case ARRAY:
            case BLOB:
                typeString = "[]";
                break;
            case RECORD:
            case MAP:
                typeString = "{}";
                break;
            case FINITE:
                List<BLangExpression> valueSpace = new ArrayList<>(((BFiniteType) bType).valueSpace);
                String value = valueSpace.get(0).toString();
                BType type = valueSpace.get(0).type;
                typeString = value;
                if (type.toString().equals("string")) {
                    typeString = "\"" + typeString + "\"";
                }
                break;
            case UNION:
                List<BType> memberTypes = new ArrayList<>(((BUnionType) bType).getMemberTypes());
                typeString = getDefaultValueForType(memberTypes.get(0));
                break;
            case STREAM:
            default:
                typeString = "()";
                break;
        }
        return typeString;
    }

    /**
     * Check whether a given symbol is client object or not.
     *
     * @param bSymbol BSymbol to evaluate
     * @return {@link Boolean}  Symbol evaluation status
     */
    public static boolean isClientObject(BSymbol bSymbol) {
        return bSymbol.type != null && bSymbol.type.tsymbol != null && SymbolKind.OBJECT.equals(bSymbol.type.tsymbol.
                                                                                                        kind) &&
               (bSymbol.type.tsymbol.flags & Flags.CLIENT) == Flags.CLIENT;
    }


    /**
     * Get the BType name as string.
     *
     * @param bType BType to get the name
     * @param ctx   LS Operation Context
     * @return {@link String}   BType Name as String
     */
    public static String getBTypeName(BType bType, LSContext ctx) {
        if (bType instanceof ConstrainedType) {
            return getConstrainedTypeName(bType, ctx);
        }
        if (bType instanceof BUnionType) {
            return getUnionTypeName((BUnionType) bType, ctx);
        }
        if (bType instanceof BTupleType) {
            return getTupleTypeName((BTupleType) bType, ctx);
        }
        if (bType instanceof BFiniteType || bType instanceof BInvokableType || bType instanceof BNilType) {
            return bType.toString();
        }
        if (bType instanceof BArrayType) {
            return getArrayTypeName((BArrayType) bType, ctx);
        }
        if (bType instanceof BRecordType) {
            return getRecordTypeName((BRecordType) bType, ctx);
        }
        return getShallowBTypeName(bType, ctx);
    }

    private static String getShallowBTypeName(BType bType, LSContext ctx) {
        if (bType.tsymbol == null) {
            return bType.toString();
        }
        if (bType instanceof BArrayType) {
            return getShallowBTypeName(((BArrayType) bType).eType, ctx) + "[]";
        }
        if (bType.tsymbol.pkgID == null) {
            return bType.tsymbol.name.getValue();
        }
        PackageID pkgId = bType.tsymbol.pkgID;
        // split to remove the $ symbol appended type name. (For the service types)
        String[] nameComponents = bType.tsymbol.name.value.split("\\$")[0].split(":");
        if (ctx != null) {
            PackageID currentPkgId = ctx.get(ServiceKeys.CURRENT_BLANG_PACKAGE_CONTEXT_KEY).packageID;
            if (pkgId.toString().equals(currentPkgId.toString()) || pkgId.getName().getValue().startsWith("lang.")) {
                return nameComponents[nameComponents.length - 1];
            }
        }
        if (pkgId.getName().getValue().startsWith("lang.")) {
            return nameComponents[nameComponents.length - 1];
        }
        return pkgId.getName().getValue() + CommonKeys.PKG_DELIMITER_KEYWORD + nameComponents[nameComponents.
                                                                                                      length - 1];
    }

    private static String getUnionTypeName(BUnionType unionType, LSContext ctx) {
        List<BType> nonErrorTypes = new ArrayList<>();
        List<BType> errorTypes = new ArrayList<>();
        StringBuilder unionName = new StringBuilder("(");
        unionType.getMemberTypes().forEach(bType -> {
            if (bType instanceof BErrorType) {
                errorTypes.add(bType);
            } else {
                nonErrorTypes.add(bType);
            }
        });
        String nonErrorsName = nonErrorTypes.stream().map(bType -> getBTypeName(bType, ctx)).collect(Collectors.joining
                ("|"));
        unionName.append(nonErrorsName);
        if (errorTypes.size() > 3) {
            if (nonErrorTypes.isEmpty()) {
                unionName.append("error");
            } else {
                unionName.append("|error");
            }
        } else if (!errorTypes.isEmpty()) {
            String errorsName = errorTypes.stream().map(bType -> getBTypeName(bType, ctx)).collect(Collectors.joining
                    ("|"));

            if (nonErrorTypes.isEmpty()) {
                unionName.append(errorsName);
            } else {
                unionName.append("|").append(errorsName);
            }
        }
        unionName.append(")");
        return unionName.toString();
    }

    private static String getTupleTypeName(BTupleType tupleType, LSContext ctx) {
        return "[" + tupleType.getTupleTypes().stream().map(bType -> getBTypeName(bType, ctx)).
                collect(Collectors.joining(",")) + "]";
    }

    private static String getRecordTypeName(BRecordType recordType, LSContext ctx) {
        if (recordType.tsymbol.kind == SymbolKind.RECORD && recordType.tsymbol.name.value.contains("$anonType")) {
            StringBuilder recordTypeName = new StringBuilder("record {");
            recordTypeName.append(CommonUtils.LINE_SEPARATOR);
            String fieldsList = recordType.fields.stream().map(field -> getBTypeName(field.type, ctx) + " " +
                                                                        field.name.getValue() + ";").collect(Collectors
                                                                                                                                                                                                                                                   .joining(CommonUtils.LINE_SEPARATOR));
            recordTypeName.append(fieldsList).append(CommonUtils.LINE_SEPARATOR).append("}");
            return recordTypeName.toString();
        }

        return getShallowBTypeName(recordType, ctx);
    }

    private static String getArrayTypeName(BArrayType arrayType, LSContext ctx) {
        return getBTypeName(arrayType.eType, ctx) + "[]";
    }

    /**
     * Get the constraint type name.
     *
     * @param bType   BType to evaluate
     * @param context Language server operation context
     * @return {@link StringBuilder} constraint type name
     */
    private static String getConstrainedTypeName(BType bType, LSContext context) {

        if (!(bType instanceof ConstrainedType)) {
            return "";
        }
        BType constraint = getConstraintType(bType);
        StringBuilder constraintName = new StringBuilder(getShallowBTypeName(bType, context));
        constraintName.append("<");

        if (constraint.tsymbol.kind == SymbolKind.RECORD && constraint.tsymbol.name.value.contains("$anonType")) {
            constraintName.append("record {}");
        } else {
            constraintName.append(getBTypeName(constraint, context));
        }

        constraintName.append(">");

        return constraintName.toString();
    }

    private static BType getConstraintType(BType bType) {
        if (bType instanceof BFutureType) {
            return ((BFutureType) bType).constraint;
        }
        if (bType instanceof BMapType) {
            return ((BMapType) bType).constraint;
        }
        if (bType instanceof BStreamType) {
            return ((BStreamType) bType).constraint;
        }
//        if (bType instanceof BTypedescType) {
//            return ((BTypedescType) bType).constraint;
//        }
        return ((BTableType) bType).constraint;

    }

    /**
     * Get the last item of the List.
     *
     * @param list List to get the Last Item
     * @param <T>  List content Type
     * @return Extracted last Item
     */
    public static <T> T getLastItem(List<T> list) {
        return (list.size() == 0) ? null : list.get(list.size() - 1);
    }

    /**
     * Get the last item of the Array.
     *
     * @param list Array to get the Last Item
     * @param <T>  Array content Type
     * @return Extracted last Item
     */
    public static <T> T getLastItem(T[] list) {
        return (list.length == 0) ? null : list[list.length - 1];
    }

    /**
     * Check whether the source is a test source.
     *
     * @param relativeFilePath source path relative to the package
     * @return {@link Boolean}  Whether a test source or not
     */
    public static boolean isTestSource(String relativeFilePath) {
        return relativeFilePath.startsWith("tests" + FILE_SEPARATOR);
    }

    /**
     * Get the Source's owner BLang package, this can be either the parent package or the testable BLang package.
     *
     * @param relativePath Relative source path
     * @param parentPkg    parent package
     * @return {@link BLangPackage} Resolved BLangPackage
     */
    public static BLangPackage getSourceOwnerBLangPackage(String relativePath, BLangPackage parentPkg) {
        return isTestSource(relativePath) ? parentPkg.getTestablePkg() : parentPkg;
    }

    /**
     * Check whether the symbol is a valid invokable symbol.
     *
     * @param symbol Symbol to be evaluated
     * @return {@link Boolean}  valid status
     */
    public static boolean isValidInvokableSymbol(BSymbol symbol) {
        if (!(symbol instanceof BInvokableSymbol)) {
            return false;
        }

        BInvokableSymbol bInvokableSymbol = (BInvokableSymbol) symbol;
        return ((bInvokableSymbol.kind == null && (SymbolKind.RECORD.equals(bInvokableSymbol.owner.kind) ||
                                                   SymbolKind.FUNCTION.equals(bInvokableSymbol.owner.kind))) ||
                SymbolKind.FUNCTION.equals(bInvokableSymbol.kind)) && (!(bInvokableSymbol.name.
                value.endsWith(BLangConstants.INIT_FUNCTION_SUFFIX) || bInvokableSymbol.
                name.value.endsWith(BLangConstants.START_FUNCTION_SUFFIX) || bInvokableSymbol.
                name.value.endsWith(BLangConstants.STOP_FUNCTION_SUFFIX)));
    }

    /**
     * Get the current module's imports.
     *
     * @param ctx LS Operation Context
     * @return {@link List}     List of imports in the current file
     */
    public static List<BLangImportPackage> getCurrentModuleImports(LSContext ctx) {
        String relativePath = ctx.get(ServiceKeys.RELATIVE_FILE_PATH_KEY);
        BLangPackage currentPkg = ctx.get(ServiceKeys.CURRENT_BLANG_PACKAGE_CONTEXT_KEY);
        BLangPackage ownerPkg = getSourceOwnerBLangPackage(relativePath, currentPkg);
        return ownerPkg.imports;
    }


    /**
     * Check whether the given node is a worker derivative node.
     *
     * @param node Node to be evaluated
     * @return {@link Boolean}  whether a worker derivative
     */
    public static boolean isWorkerDereivative(BLangNode node) {
        return (node instanceof BLangSimpleVariableDef) && ((BLangSimpleVariableDef) node).var.expr != null &&
               ((BLangSimpleVariableDef) node).var.expr.type instanceof BFutureType && ((BFutureType)
                ((BLangSimpleVariableDef) node).var.expr.type).workerDerivative;
    }


    /**
     * Get the package name components combined.
     *
     * @param importPackage BLangImportPackage node
     * @return {@link String}   Combined package name
     */
    public static String getPackageNameComponentsCombined(BLangImportPackage importPackage) {
        return importPackage.pkgNameComps.stream().map(id -> id.value).collect(Collectors.joining("."));
    }


    private static List<BField> getRecordRequiredFields(BRecordType recordType) {
        return recordType.fields.stream().filter(field -> (field.symbol.flags & Flags.REQUIRED) == Flags.REQUIRED).
                collect(Collectors.toList());
    }

    /**
     * Get the completion item insert text for a BField.
     *
     * @param bField BField to evaluate
     * @return {@link String} Insert text
     */
    private static String getRecordFieldCompletionInsertText(BField bField, int tabOffset) {
        BType fieldType = bField.getType();
        StringBuilder insertText = new StringBuilder(bField.getName().getValue() + ": ");
        if (fieldType instanceof BRecordType) {
            List<BField> requiredFields = getRecordRequiredFields((BRecordType) fieldType);
            if (requiredFields.isEmpty()) {
                insertText.append("{").append("${1}}");
                return insertText.toString();
            }
            insertText.append("{").append(LINE_SEPARATOR);
            int tabCount = tabOffset;
            for (BField requiredField : requiredFields) {
                insertText.append(String.join("", Collections.nCopies(tabCount + 1, "\t"))).
                        append(getRecordFieldCompletionInsertText(requiredField, tabCount)).append(String.
                                                                                                                                                                                                            join("", Collections.nCopies(tabCount, "\t"))).
                                  append(LINE_SEPARATOR);
                tabCount++;
            }
            insertText.append(String.join("", Collections.nCopies(tabOffset, "\t"))).append("}").
                    append(LINE_SEPARATOR);
        } else if (fieldType instanceof BArrayType) {
            insertText.append("[").append("${1}").append("]");
        } else if (fieldType.tsymbol != null && fieldType.tsymbol.name.getValue().equals("string")) {
            insertText.append("\"").append("${1}").append("\"");
        } else {
            insertText.append("${1:").append(getDefaultValueForType(bField.getType())).append("}");
            if (bField.getType() instanceof BFiniteType || bField.getType() instanceof BUnionType) {
                insertText.append(getFiniteAndUnionTypesComment(bField.getType()));
            }
        }

        return insertText.toString();
    }

    ///////////////////////////////
    /////      Predicates     /////
    ///////////////////////////////

    /**
     * Generates a random name.
     *
     * @param value    index of the argument
     * @param argNames argument set
     * @return random argument name
     */
    public static String generateName(int value, Set<String> argNames) {
        StringBuilder result = new StringBuilder();
        int index = value;
        while (--index >= 0) {
            result.insert(0, (char) ('a' + index % 26));
            index /= 26;
        }
        while (argNames.contains(result.toString())) {
            result = new StringBuilder(generateName(++value, argNames));
        }
        return result.toString();
    }


    private static String generateVariableName(int value, BLangNode bLangNode, Set<String> names) {
        String newName = generateName(value, names);
        if (bLangNode instanceof BLangInvocation && value == 1) {
            newName = ((BLangInvocation) bLangNode).name.value;
            BiFunction<String, String, String> replacer = (search, text) -> (text.startsWith(search)) ?
                                                                            text.replaceFirst(search, "")
                                                                                                      : text;
            // Replace common prefixes
            newName = replacer.apply("get", newName);
            newName = replacer.apply("put", newName);
            newName = replacer.apply("delete", newName);
            newName = replacer.apply("update", newName);
            newName = replacer.apply("set", newName);
            newName = replacer.apply("add", newName);
            newName = replacer.apply("create", newName);
            // Remove '_' underscores
            while (newName.contains("_")) {
                String[] parts = newName.split("_");
                List<String> restParts = Arrays.stream(parts, 1, parts.length).collect(Collectors.
                                                                                                         toList());
                newName = parts[0] + StringUtils.capitalize(String.join("", restParts));
            }
            // If empty, revert back to original name
            if (newName.isEmpty()) {
                newName = ((BLangInvocation) bLangNode).name.value;
            }
            // Lower first letter
            newName = newName.substring(0, 1).toLowerCase(Locale.getDefault()) + newName.substring(1);
            // if already available, try appending 'Result'
            Iterator<String> iterator = names.iterator();
            boolean alreadyExists = false;
            boolean appendResult = true;
            boolean appendOut = true;
            String suffixResult = "Result";
            String suffixOut = "Out";
            while (iterator.hasNext()) {
                String next = iterator.next();
                if (next.equals(newName)) {
                    alreadyExists = true;
                } else if (next.equals(newName + suffixResult)) {
                    appendResult = false;
                } else if (next.equals(newName + suffixOut)) {
                    appendOut = false;
                }
            }
            // if already available, try appending 'Result' or 'Out'
            if (alreadyExists && appendResult) {
                newName = newName + suffixResult;
            } else if (alreadyExists && appendOut) {
                newName = newName + suffixOut;
            }
            // if still already available, try a random letter
            while (names.contains(newName)) {
                newName = generateVariableName(++value, bLangNode, names);
            }
        }
        return newName;
    }


    private static String getFiniteAndUnionTypesComment(BType bType) {
        if (bType instanceof BFiniteType) {
            List<BLangExpression> valueSpace = new ArrayList<>(((BFiniteType) bType).valueSpace);
            return " // Values allowed: " + valueSpace.stream().map(Object::toString).
                    collect(Collectors.joining("|"));
        } else if (bType instanceof BUnionType) {
            List<BType> memberTypes = new ArrayList<>(((BUnionType) bType).getMemberTypes());
            return " // Values allowed: " + memberTypes.stream().map(BType::toString).
                    collect(Collectors.joining("|"));
        }

        return "";
    }


    public static BPackageSymbolDTO getPackageSymbolDTO(LSContext ctx, String pkgName) {
        Optional bLangImport = CommonUtils.getCurrentModuleImports(ctx).stream().
                filter(importPkg -> importPkg.getAlias().getValue().equals(pkgName)).findFirst();
        String realPkgName;
        String realOrgName;

        if (bLangImport.isPresent()) {
            // There is an added import statement.
            realPkgName = CommonUtils.getPackageNameComponentsCombined(((BLangImportPackage) bLangImport.get()));
            realOrgName = ((BLangImportPackage) bLangImport.get()).getOrgName().getValue();
        } else {
            realPkgName = pkgName;
            realOrgName = "";
        }

        return new BPackageSymbolDTO.BPackageSymbolDTOBuilder().setName(realPkgName).setOrgName(realOrgName).build();
    }


    private static String getErrorDetails(TextDocumentIdentifier textDocument, Throwable error, Position... position) {
        String msg = error.getMessage();
        StringBuilder result = new StringBuilder("{");
        if (textDocument != null) {
            result.append("uri: ").append(textDocument.getUri().replaceFirst("file://", ""));
        }
        if (position != null && position[0] != null) {
            if (position.length == 2) {
                // Range
                result.append(", line: ").append(position[0].getLine() + 1).append(", col:").
                        append(position[0].getCharacter() + 1);
                result.append("- line: ").append(position[1].getLine() + 1).append(", col:").
                        append(position[1].getCharacter() + 1);
            } else {
                // Position
                result.append(", line: ").append(position[0].getLine() + 1).append(", col:").
                        append(position[0].getCharacter() + 1);
            }
        }
        if (msg != null && !msg.isEmpty()) {
            result.append(", error: ").append(msg);
        } else {
            result.append(", error: ").append(error.toString());
            for (StackTraceElement elm : error.getStackTrace()) {
                if (elm.getClassName().startsWith("org.wso2.")) {
                    result.append(", ").append(elm.toString());
                    break;
                }
            }
        }
        result.append("}");
        return result.toString();
    }


}
