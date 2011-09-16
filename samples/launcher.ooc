import herge_output/[AST, GrammarReader]

import structs/ArrayList
import io/File

main: func (args: ArrayList<String>) {

    if(args size > 1) {
        args removeAt(0) 
        args each(|arg|
            tok := AST parse(GrammarReader new(File new(arg) read()))
            if(tok) {
                tok print()
            } else {
                "Invalid input!" println()
            }
        )
    } else {
        "Usage: %s [FILE]" printfln(args[0])
    }

}
