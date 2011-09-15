import structs/[ArrayList, HashMap]
import text/[Opts, Regexp]

import GrammarReader

/**
 * A rule can be matched against some text
 */
Rule: abstract class {

}

TopRule: class extends Rule {

    paramNames := ArrayList<String> new()
    params := HashMap<String, Rule> new()

    resolveParams: func (g: Grammar) {
        for(name in paramNames) {
            rule := g rules[name]
            if(!rule) {
                Exception new("Undefined rule %s" format(name)) throw()
            }
            params put(name, rule)
        }
    }

}

/**
 * "some string here"
 * matches the string exactly or nothing
 */
SymbolRule: class extends Rule {

    symbol: String

    init: func(=symbol) {}

}

/**
 * somerule? 
 * matches the rule exactly once or none at all
 */
ZeroOrNone: class extends Rule {

    rule: Rule

    init: func(=rule) {}

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

}

/**
 * somerule | someotherrule
 */
Or: class extends Rule {

    leftRule, rightRule: Rule

    init: func(=leftRule, =rightRule) {}

}

Grammar: class {

    word := Regexp compile("[A-Za-z_]*")
    ws := Regexp compile("[ \t\n]*") 

    rules := HashMap<String, TopRule> new()
    reader: GrammarReader

    init: func (path: String) {
        reader = GrammarReader new(path)
        readTopLevels()
    }

    readTopLevels: func {
        // skip whitespace
        reader readRegexp(ws)

        name := reader readRegexp(word)
        "Got name %s" printfln(name)
    }

}

main: func (mainArgs: ArrayList<String>) {

    opts := Opts new(mainArgs)

    args := opts args
    args each(|arg|
        g := Grammar new(arg)
    )

}
