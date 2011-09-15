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

    instance: Rule

    init: func (=name, =paramNames, =instance) {
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
        "%s%s := %s" format(name, paramRepr, instance _)
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

NamedRule: class extends Rule {

    name: String
    instance: Rule

    init: func(=name, =instance)

    toString: func -> String {
        "%s:%s" format(name, instance _)
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
 * Must match somerule, or someotherrule
 */
OrRule: class extends Rule {

    leftRule, rightRule: Rule

    init: func(=leftRule, =rightRule) {}

    toString: func -> String {
        "%s | %s" format(leftRule _, rightRule _)
    }

}

/**
 * somerule someotherrule
 * Must match somerule, then someotherrule
 */
AndRule: class extends Rule {

    leftRule, rightRule: Rule

    init: func(=leftRule, =rightRule) {}

    toString: func -> String {
        "%s %s" format(leftRule _, rightRule _)
    }

}

Grammar: class {

    // ----- Regular expressions
    word := Regexp compile("[A-Za-z\\-]*")
    wordColon := Regexp compile("([A-Za-z\\-]*):")
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

        if(ruleName) rule = NamedRule new(ruleName trim(':'), rule)

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

main: func (mainArgs: ArrayList<String>) {

    opts := Opts new(mainArgs)

    args := opts args
    args each(|arg|
        g := Grammar new(arg)
    )

}
