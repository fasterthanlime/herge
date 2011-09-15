import structs/[ArrayList, HashMap]
import text/[Opts, Regexp]

import GrammarReader, io/File

/**
 * A rule can be matched against some text
 */
Rule: abstract class {

    resolve: func (g: Grammar) {
        Exception new("Class %s is doing nothing to resolve! Aborting" format(class name)) throw()
    }

    toString: abstract func -> String

    _: String {
        get {
            toString()
        }
    }

}

TopRule: class extends Rule {

    name: String
    paramNames: ArrayList<String>
    params := HashMap<String, Rule> new()

    instances := ArrayList<Rule> new()

    init: func (=name, =paramNames) {
    }

    resolve: func (g: Grammar) {
        for(name in paramNames) {
            rule := g rules[name]
            if(!rule) {
                Exception new("Undefined rule %s" format(name)) throw()
            }
            params put(name, rule)
        }
    }

    toString: func -> String {
        paramRepr := paramNames ? "<" + paramNames join(", ") + ">" : ""
        "%s%s := %s" format(name, paramRepr, instances map(|x| x _) join(" "))
    }

}

/**
 * "some string here"
 * matches the string exactly or nothing
 */
SymbolRule: class extends Rule {

    symbol: String

    init: func(=symbol) {}

    toString: func -> String { "\"%s\"" format(symbol) }

}

InstanceRule: class extends Rule {

    refName: String
    ref: Rule
    params := ArrayList<Rule> new()

    init: func (=refName) {}

    toString: func -> String {
        paramRepr := params empty?() ? "" : "<" + params map(|x| x _) join(", ") + ">"
        "%s%s" format(refName, paramRepr)
    }

}

RegexpRule: class extends Rule {

    expr: String

    init: func(=expr) {}

    toString: func -> String {
        expr
    }

}

/**
 * somerule? 
 * matches the rule exactly once or none at all
 */
ZeroOrOne: class extends Rule {

    rule: Rule

    init: func(=rule) {}

    toString: func -> String {
        "%s?" format(rule _)
    }

}

/**
 * somerule*
 * matches the rule from zero to infinite times
 * note that matching it infinite times might take
 * a non-finite amount of time to complete. Your call.
 */
ZeroOrMore: class extends Rule {

    rule: Rule

    init: func(=rule) {}

    toString: func -> String {
        "%s*" format(rule _)
    }

}

/**
 * somerule | someotherrule
 */
OrRule: class extends Rule {

    leftRule, rightRule: Rule

    init: func(=leftRule, =rightRule) {}

    toString: func -> String {
        "%s | %s" format(leftRule _, rightRule _)
    }

}

Grammar: class {

    // ----- Regular expressions
    word := Regexp compile("[A-Za-z_]*")
    allWs := Regexp compile("[ \t\n]*") 
    ws := Regexp compile("[ \t]*")
    assDecl := Regexp compile(":=[ \t]*")
    comma := Regexp compile(",[ \t]*")

    // ----- Grammar content
    rules := HashMap<String, TopRule> new()
    reader: GrammarReader

    init: func (path: String) {
        reader = GrammarReader new(File new(path) read())
        readTopLevels()
    }

    readTopLevels: func {
        while (true) {
            skipAllWhitespace()
            if(!reader hasNext?()) return

            name := reader readRegexp(word)
            if(name empty?()) reader error("Expected toplevel rule name")

            params: ArrayList<String>

            skipWhitespace()
            if(reader peek() == '<') {
                reader read()
                paramString := reader readUntil('>') 
                params = GrammarReader new(paramString) readCommaList()
            }

            rule := TopRule new(name, params)

            skipWhitespace()
            if (!reader readRegexp(assDecl)) reader error("Expected ':=' here")

            while(reader hasNext?() && reader peek() != '\n') {
                skipWhitespace()
                instance := readRule()
                if(!instance) reader error("Expected instance here")
                rule instances add(instance)    
            }

            ">> %s" printfln(rule _)
            rules put(name, rule)
        }
    }

    readRule: func -> Rule {
        rule := match (reader peek()) {
            case '"' =>
                reader read()
                SymbolRule new(reader readUntil('"')) 
            case '[' =>
                reader read()
                expr := "[%s]" format(reader readUntil(']'))
                RegexpRule new(expr)
            case =>
                name := reader readRegexp(word)
                if(!name) reader error("Expected rule here")
                instance := InstanceRule new(name)
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
                    reader read()
                }
                instance
        }

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
                case =>
                    break 
            }
        }

        "Just read rule %s" printfln(rule _)
        rule
    }

    skipWhitespace: func {
        reader readRegexp(ws)
    }

    skipAllWhitespace: func {
        reader readRegexp(allWs)
    }

}

main: func (mainArgs: ArrayList<String>) {

    opts := Opts new(mainArgs)

    args := opts args
    args each(|arg|
        g := Grammar new(arg)
    )

}
