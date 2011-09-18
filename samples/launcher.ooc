import herge_output/[AST, GrammarReader]

import structs/ArrayList
import io/[File, FileReader]

main: func (args: ArrayList<String>) {

    if(args size < 2) {
        args add("-")
        "No input file specified, reading from stdin..." println()
    }

    args removeAt(0) 
    args each(|arg|
        tok := AST parse(GrammarReader new(match arg {
            case "-" =>
               FileReader new(stdin)
            case =>
               FileReader new(arg)
            } readAll()))

        if(tok) {
            tok print()
        } else {
            "Invalid input!" println()
        }
    )

}
