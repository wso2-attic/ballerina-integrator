package snippet;

public class Snippet {
    private String name;
    private String imports;
    private String trigger;
    private String code;

    public Snippet(String name, String imports, String trigger, String code) {
        this.name = name;
        this.imports = imports;
        this.trigger = trigger;
        this.code = code;
    }

    public Snippet() {
    }

    public Snippet(String trigger) {
        this.trigger = trigger;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getImports() {
        return imports;
    }

    public void setImports(String imports) {

        this.imports = imports;
    }

    public String getTrigger() {
        return trigger;
    }

    public void setTrigger(String trigger) {
        this.trigger = trigger;

        this.trigger = "public static final String " + name + "=" + this.trigger;

    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;

        String resourceConfig = "";
        String resource = "";
    }
}

