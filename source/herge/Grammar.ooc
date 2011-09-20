import text/Regexp
import structs/[HashMap, ArrayList]
import io/File
import Rule, GrammarReader, BuildParams

Grammar: class {

    // ----- Regular expressions
    word := Regexp compile("[A-Za-z\\-]*")
    wordColon := Regexp compile("([A-Za-z\\-]*):")
    allWs := Regexp compile("[ \t\n]*") 
    ws := Regexp compile("[ \t]*")
    assDecl := Regexp compile(":=[ \t]*")
    comma := Regexp compile(",[ \t]*")

    // ----- Grammar content
    path: String
    rules := HashMap<String, TopRule> new()
    reader: GrammarReader

    init: func (=path, params: BuildParams) {
        reader = GrammarReader new(File new(path) read())
        readTopLevels()

        for(rule in rules) {
            rule resolve(this)
        }

        for(rule in rules) {
            rule writeFile(this, params)
        }

        ["Token", "GrammarReader"] as ArrayList<String> each(|builtin|
            File new(params distrib, "source/herge/%s.ooc" format(builtin)) copyTo(File new(params outPath, builtin + ".ooc"))
        )
    }

    readTopLevels: func {
        while (true) {
            skipAllWhitespace()
            if(!reader hasNext?()) return
            if(reader peek() == '#') {
                reader readLine()
                continue
            }

            name := reader readRegexp(word)
            if(name empty?()) reader error("Expected toplevel rule name")

            params: ArrayList<String>

            skipWhitespace()
            if(reader peek() == '<') {
                reader read()
                paramString := reader readUntil('>') 
                params = GrammarReader new(paramString) readCommaList()
            }


            skipWhitespace()
            if (!reader readRegexp(assDecl)) reader error("Expected ':=' here")

            skipWhitespace()
            instance := readRule()
            if(!instance) reader error("Expected instance here")

            rule := TopRule new(name, params, instance)
            ">> %s" printfln(rule _)
            rules put(name, rule)
        }
    }

    readRule: func -> Rule {
        ruleName := reader readRegexp(wordColon, 1)
        skipWhitespace()

        rule := match (reader peek()) {
            case '"' =>
                reader read()
                SymbolRule new(reader readUntil('"')) 
            case '[' =>
                reader read()
                expr := "[%s]" format(reader readUntil(']'))
                RegexpRule new(expr)
            case '(' =>
                "Reading paren" println()
                reader read()
                rule := readRule() 
                skipWhitespace()
                if(reader read() != ')') reader error("Expected closing parenthesis")
                rule
             case =>
                instanceName := reader readRegexp(word)
                "Got instanceName %s" printfln(instanceName)
                if(instanceName empty?()) reader error("Expected rule here")

                instance := InstanceRule new(instanceName)
                skipWhitespace()
                if(reader peek() == '<') {
                    reader read()
                    skipWhitespace()
                    while(reader peek() != '>') {
                        skipWhitespace()
                        instance params add(readRule())
                        if(!reader readRegexp(comma)) {
                            reader error("Invalid instance param list, expected comma")
                        }
                    }
                    if(reader read() != '>') reader error("Expected '>' here")
                }

                instance
        }

        if(ruleName && !ruleName empty?()) rule = NamedRule new(ruleName trim(':'), rule)

        "Just read %s %s" printfln(rule class name, rule _)

        while (true) {
            skipWhitespace()
            match (reader peek()) {
                case '*' => 
                    reader read()
                    rule = ZeroOrMore new(rule)
                case '?' =>
                    reader read()
                    rule = ZeroOrOne new(rule)
                case '|' =>
                    reader read()
                    skipWhitespace()
                    rightRule := readRule()
                    rule = OrRule new(rule, rightRule)
                case '\\' =>
                    skipAllWhitespace()
                case '\n' =>
                    break
                case '>' =>
                    break
                case ')' =>
                    break

                case =>
                    rightRule := readRule() 
                    rule = AndRule new(rule, rightRule)
            }
            "Just read %s %s" printfln(rule class name, rule _)
        }

        rule
    }

    skipWhitespace: func {
        reader readRegexp(ws)
    }

    skipAllWhitespace: func {
        reader readRegexp(allWs)
    }

}


