import text/Opts, os/Env

BuildParams: class {
    outPath := "herge_output"
    prefix := ""
    distrib: String

    init: func (opts: Opts) {
        opts opts each(|key, value|
            match key {
                case "outpath" =>
                    outPath = value
                case "prefix" =>
                    prefix = value
                case =>
                    "Unknown option --%s" printfln(key)
            }
        )

        distrib = Env get("HERGE_DISTRIB")
        if(!distrib) {
            "Herge couldn't find its distribution folder - for now, please set the HERGE_DISTRIB environment variable to the folder containing source/" println()
            exit(1)
        }

    }
}


