package snippet;

import javafx.util.Pair;

import javax.tools.JavaCompiler;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class SnippetGenerator {
    public static Pair<HashMap, Integer> readFile(String inputDir) throws Exception {
        File f = Paths.get("src", "main", "resources", "Snippets").toFile();
        ArrayList<File> filesArr = new ArrayList<File>(Arrays.asList(f.listFiles()));

        HashMap map = new HashMap();

        for (int i = 0; i < filesArr.size(); i++) {

            String line;
            BufferedReader reader = Files.newBufferedReader(Paths.get(String.valueOf(filesArr.get(i))));
            String pr = "";
            while ((line = reader.readLine()) != null) {
                String[] parts = line.split("-", 2);

                if (parts.length >= 2) {

                    String key = parts[0] + i;
                    String value = parts[1];

                    map.put(key, value);
                } else if (parts.length < 2) {

                    pr = pr + "\n" + parts[0];
                    String k = "SnippetGen" + i;

                    map.put(k, pr);
                }
            }
            reader.close();
        }

        generateSnippet(map, filesArr.size());

        return new Pair<HashMap, Integer>(map, filesArr.size());
    }


    public static HashMap generateSnippet(HashMap mp, int size) throws Exception {
        String sName = "";
        String sImports = "";
        String sTrigger = "";
        String sCode = "";
        String sSnip = "";

        ArrayList<String> snippetsNameArr = new ArrayList<>();
        ArrayList<String> snippetsImportsArr = new ArrayList<>();
        ArrayList<String> snippetsTriggerArr = new ArrayList<>();
        ArrayList<String> snippetsArr = new ArrayList<>();
        ArrayList<String> snipArr = new ArrayList<>();
        HashMap<String, ArrayList> snipMap = new HashMap<String, ArrayList>();

        for (int i = 0; i < size; i++) {
            sName = (String) mp.get("SName " + i);
            sName = sName.toUpperCase();
            snippetsNameArr.add(sName);

            sImports = (String) mp.get("Imports " + i);
            snippetsImportsArr.add(sImports);

            sTrigger = (String) mp.get("Trigger " + i);
            snippetsTriggerArr.add(sTrigger);

            sSnip = (String) mp.get("Snippet " + i);
            snipArr.add(sSnip);

            sCode = (String) mp.get("SnippetGen" + i);
            snippetsArr.add(sSnip + sCode);

            Snippet snp = new Snippet(sName, sImports, sTrigger, sCode);

            snp.setName(sName);
            snp.setImports(sImports);
            snp.setTrigger(sTrigger);
            snp.setCode(sSnip + sCode);
        }

        snipMap.put("Name", snippetsNameArr);
        snipMap.put("Imports", snippetsImportsArr);
        snipMap.put("Trigger", snippetsTriggerArr);
        snipMap.put("Code", snippetsArr);

        return snipMap;
    }


    public static void generateItemResolver(HashMap hs) throws Exception {

        File sourceFile = Paths.get("../auto-generated-files", "src", "main", "java", "generated",
                                                                            "ItemResolverConstants.java").toFile();

        sourceFile.createNewFile();


        ArrayList triggerArr = new ArrayList();
        ArrayList nameArr = new ArrayList();

        triggerArr = (ArrayList) hs.get("Trigger");
        nameArr = (ArrayList) hs.get("Name");

        String content = "";

        if (sourceFile.exists()) {
            sourceFile.delete();
        }

        sourceFile.createNewFile();

        String content1 = "package generated;" + "\n" + "\n" + "public class ItemResolverConstants" + "{ " + "\n" +
                          "\n" + "  // Symbol Types Constants\n" +
                          "    public static final String SNIPPET_TYPE = \"Snippet\";\n" +
                          "    public static final String RESOURCE = \"resource\";\n" +
                          "    public static final String RECORD_TYPE = \"type <RecordName> record\";\n" +
                          "    // End Symbol Types Constants" ;

        for (int i = 0; i < triggerArr.size(); i++) {
            String co = (String) triggerArr.get(i);
            String na = (String) nameArr.get(i);
            String[] ind = na.split("\\(");
            na = ind[0];
            co = na + "" + " =" + co;
            content = content + "\n" + "public static final String" + co + ";";
        }

        content1 = content1 + "\n" + content + "\n" + "\n" + "}";

        System.out.println("File is created!");

        FileWriter writer = new FileWriter(sourceFile);
        writer.write(content1);
        writer.close();
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null,
                                                                                                    null);

        sourceFile.createNewFile();

        fileManager.close();
    }


    public static void generateSnippetName(HashMap hs) throws Exception {

        File sourceFile2 = Paths.get("../auto-generated-files", "src", "main", "java", "generated",
                                                                                            "Snippets.java").toFile();

        ArrayList snippetArr = new ArrayList();
        snippetArr = (ArrayList) hs.get("Name");

        String content = "";

        if (sourceFile2.exists()) {
            sourceFile2.delete();
        }

        sourceFile2.createNewFile();

        String content1 = "package generated;\n" + "\n" + "\n"  +
                          "import Utils.SnippetsBlock;" + "\n" +
                          "    /**\n" + "     " +
                          "* Snippets for the Ballerina Integrator.\n" + "     */\n" + "\n" +
                          "public enum Snippets {\n ";

        String content2 = "private String snippetName;\n" + "   " +
                          " private SnippetsBlock snippetBlock;\n" + "\n" +
                          "    Snippets(SnippetsBlock snippetBlock) {\n" + "       " +
                          " this.snippetName = null;\n" + "        " +
                          "this.snippetBlock = snippetBlock;\n" + "    }\n" + "\n" + " " +
                          "  Snippets(String snippetName, SnippetsBlock snippetBlock) {\n" + "      " +
                          "  this.snippetName = snippetName;\n" + "     " + "   this.snippetBlock = snippetBlock;\n" +
                          "    }\n" + "\n" + "  " + "    /**\n" + "   " + "  * Get the Snippet Name.\n" + "     *\n" +
                          "     * @return {@link String} snippet name\n" + "   " + "  */\n" +
                          "    public String snippetName() {\n" + "        return this.snippetName;\n" + "  " + "  }\n"
                          + "\n" + "    /**\n" + "     * Get the SnippetBlock.\n" + "     *\n" +
                          "     * @return {@link SnippetsBlock} SnippetBlock\n" + "     */\n" +
                          "    public SnippetsBlock get() {\n" + "        return this.snippetBlock;\n" +
                          "    }\n" + "}";

        for (int i = 0; i < snippetArr.size(); i++) {
            String co = (String) snippetArr.get(i);
            String na = "";
            String nam = (String) snippetArr.get(i);
            String[] ind = nam.split("\\(");
            na = ind[0];
            co = na + "(" + "SnippetsContent." + co.trim() + ")";

            if (i < (snippetArr.size() - 1)) {
                content = content + "\n" + co + ",";
            } else {
                content = content + "\n" + co + ";" + "\n";
            }
        }

        content1 = content1 + "\n" + content + "\n" + content2;

        FileWriter writer = new FileWriter(sourceFile2);
        writer.write(content1);
        writer.close();
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null,
                                                                                                   null);

        fileManager.close();
    }


    // Generate Snippet Content
    public static void generateSnippetContent(HashMap hs) throws Exception {
        File sourceFile3 = Paths.get("../auto-generated-files", "src", "main", "java", "generated",
                                                                                     "SnippetsContent.java").toFile();

        ArrayList codeArr = new ArrayList();
        ArrayList nameArr = new ArrayList();
        ArrayList importArr = new ArrayList();
        ArrayList splitImports = new ArrayList();


        codeArr = (ArrayList) hs.get("Code");
        nameArr = (ArrayList) hs.get("Name");
        importArr = (ArrayList) hs.get("Imports");

        String content = "";

        if (sourceFile3.exists()) {
            sourceFile3.delete();
        }
        sourceFile3.createNewFile();

        String content2 = "package generated;\n" + "\n" + "import org.apache.commons.lang3.tuple.ImmutablePair;\n" +
                          "import Utils.SnippetsBlock;\n" +
                          "import org.ballerinalang.langserver.common.utils.CommonUtil;\n" +  "\n" + "\n" + "\n" +
                          "public class SnippetsContent {\n" + "\n" + "    private SnippetsContent() {\n" + "    } ";

        String snipPart1 = "";
        String snipPart2 = "";
        String snipPart3 = "";
        String snipPart4 = "";
        String snipPart5 = "";
        String snipPart6 = "";
        String fSnip = "";
        String content1 = "";
        String content3 = "";
        String snipPartfin = "";

        for (int i = 0; i < codeArr.size(); i++) {
            String co = codeArr.get(i).toString();
            String na = (String) nameArr.get(i);
            String im = (String) importArr.get(i);

            snipPart1 = "\n" + "\n" + "public static SnippetsBlock " + na + " {";
            String[] imArr = im.split(",");

            for (int j = 0; j < imArr.length; j++) {
                String[] x = ((imArr[j].toString()).split("/"));
                splitImports.add(x[1]);
            }

            for (int k = 0; k < splitImports.size(); k++) {
                snipPart2 = snipPart2 + "\n" + "\t" + "ImmutablePair<String, String> imports" +
                            k + " = new ImmutablePair<> (\"ballerina\"" + "," + "\"" + splitImports.get(k) + ")" + ";";

                snipPart6 =  snipPart6 +  "," +"imports"+ k ;

            }
            snipPart3 = "\n" + "\n" + "\t" + "String snippet =  " + co;

            snipPart4 = "\n" + "\n" + "return new SnippetsBlock(ItemResolverConstants.RESOURCEDEFINITION, snippet," +
                        "ItemResolverConstants.SNIPPET_TYPE,\n" + " SnippetsBlock.SnippetType.SNIPPET "  ;

             snipPart5 =  ");  ";

             snipPartfin = snipPart4 + snipPart6 +snipPart5 ;

            content1 = snipPart1 + snipPart2 + snipPart3 + snipPartfin + "}";

            fSnip = fSnip + content1;
            splitImports.clear();
            snipPart2 = "";
            snipPart6 = "";
        }

        content3 = content2 + "\n" + fSnip + "\n" + "}";

        System.out.println("File is created!");

        FileWriter writer = new FileWriter(sourceFile3);
        writer.write(content3);
        writer.close();
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null,
                                                                                                        null);
        fileManager.close();
    }


     public static void generateTopLevelScope(HashMap hs) throws Exception {

         File sourceFile5 = Paths.get("../auto-generated-files", "src", "main", "java", "generated",
                                                                                       "TopLevelScope.java").toFile();

         ArrayList snippetArr = new ArrayList();
         snippetArr = (ArrayList) hs.get("Name");

         String content = "";
         String content2 = "";
         String tmp = "";

         if (sourceFile5.exists()) {
             sourceFile5.delete();
         }

         sourceFile5.createNewFile();

         String content1 = "package generated;\n" + "\n" +
                           "import org.antlr.v4.runtime.CommonToken;\n" +
                           "import org.ballerinalang.annotation.JavaSPIService;\n" +
                           "import org.ballerinalang.langserver.common.CommonKeys;\n" +
                           "import org.ballerinalang.langserver.compiler.LSContext;\n" +
                           "import org.ballerinalang.langserver.completions.SymbolInfo;\n" +
                           "import org.ballerinalang.langserver.completions.providers.scopeproviders." +
                                                                                "TopLevelScopeProvider;\n" +
                           "import org.ballerinalang.langserver.completions.spi.LSCompletionProvider;\n" +
                           "import org.eclipse.lsp4j.CompletionItem;\n" +
                           "import org.wso2.ballerinalang.compiler.parser.antlr4.BallerinaParser;\n" +
                           "import org.wso2.ballerinalang.compiler.tree.BLangPackage;\n" +
                           "\n" + "import java.util.ArrayList;\n" + "import java.util.Collection;\n" +
                           "import java.util.List;\n" + "import java.util.Optional;\n" + "\n" +
                           "@JavaSPIService(\"org.ballerinalang.langserver.completions.spi.LSCompletionProvider\")\n" +
                           "public class TopLevelScope extends TopLevelScopeProvider {\n" + "\n" +
                           "    public static Precedence precedence;\n" + "\n" +
                           "    public TopLevelScope() {\n" + "        this.attachmentPoints.add(BLangPackage.class);"
                                                                                                               + "\n" +
                           "        this.precedence = Precedence.HIGH;\n" + "    }\n" + "\n" + "    /**\n" +
                           "     * Get a static completion Item for the given snippet.\n" + "     *\n" +
                           "     * @param snippet Snippet to generate the static completion item\n" +
                           "     * @return {@link CompletionItem} Generated static completion Item\n" +
                           "     */\n" + "\n" +
                           "    protected CompletionItem getStaticItem(LSContext ctx, Snippets snippet) {\n" +
                           "        return snippet.get().build(ctx);\n" + "    }\n" + "\n" +
                           "    public static final LSContext.Key<List<CommonToken>> LHS_DEFAULT_TOKENS_KEY = " +
                                                                                           "new LSContext.Key<>();\n" +
                           "\n" + "\n" + "    //Override the getCompletions method in LSCompletion Provider\n" +
                           "    @Override\n" +
                           "    public List<CompletionItem> getCompletions(LSContext ctx) {\n" +
                           "         ArrayList<CompletionItem> completionItm = new ArrayList<>();\n" +
                           "        Optional<LSCompletionProvider> contextProvdr = this.getContextProvider(ctx);\n" +
                           "        List<CommonToken> lhsDefaultTokens = ctx.get(LHS_DEFAULT_TOKENS_KEY);\n" + "\n" +
                           "        if (contextProvdr.isPresent()) {\n" +
                           "            return contextProvdr.get().getCompletions(ctx);\n" + "        }\n" +
                           "\n" +
                           "        if (!(lhsDefaultTokens != null && lhsDefaultTokens.size() >= 2 && " +
                                                                          "BallerinaParser.LT == lhsDefaultTokens\n" +
                           " .get(lhsDefaultTokens.size() - 1).getType())) {\n" +
                           "            completionItm.addAll(addTopLevelItem(ctx));\n" + "        }\n" +
                           "        List<SymbolInfo> visibleSymbols = new ArrayList<>" +
                           "(ctx.get(CommonKeys.VISIBLE_SYMBOLS_KEY));\n" +
                           "        completionItm.addAll((Collection<? extends CompletionItem>) " +
                           "getBasicTypes(visibleSymbols));\n" +
                           "        completionItm.addAll((Collection<? extends CompletionItem>) " +
                           "this.getPackagesCompletionItems(ctx));\n" +
                           "\n" + "        return completionItm;\n" + "    }\n" + "\n" + "\n" +
                           "    protected List<CompletionItem> addTopLevelItem(LSContext context) {\n" +
                           "        ArrayList<CompletionItem> completionItemsArr = new ArrayList<>(); " +"\t";


         for (int i = 0; i < snippetArr.size(); i++) {
             String co = (String) snippetArr.get(i);
             String na = "";
             String nam = (String) snippetArr.get(i);
             String[] ind = nam.split("\\(");
             na = ind[0];
             co = "\t" + "\t" + "completionItemsArr.add(getStaticItem(context, Snippets."+na  + "));" + "\n";

             tmp = tmp +co;
         }

         content2 = "\n" + " return completionItemsArr;\n" + "    }\n" + "}\n";

         content = content1 + "\n" + tmp + "\n" + content2;

         System.out.println("File is created!");

         FileWriter writer = new FileWriter(sourceFile5);
         writer.write(content);
         writer.close();
         JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
         StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null,
                                                                                                    null);

         sourceFile5.createNewFile();

         fileManager.close();

     }

    public static void main(String[] args) throws Exception {
        Pair<HashMap, Integer> pair = readFile("Snippets");
        HashMap hsmp = generateSnippet(pair.getKey(), pair.getValue());
        generateItemResolver(hsmp);
        generateSnippetContent(hsmp);
        generateSnippetName(hsmp);
        generateTopLevelScope(hsmp);

    }
}

