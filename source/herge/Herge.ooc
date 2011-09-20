import Grammar, BuildParams
import structs/ArrayList, text/Opts

Herge: class {
    version := static "0.0"

    init: func (mainArgs: ArrayList<String>) {
        opts := Opts new(mainArgs)

        params := BuildParams new(opts)
        opts args each(|arg|
            g := Grammar new(arg, params)
        )
    }
}

