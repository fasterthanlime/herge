import GrammarReader

Token: class {
    start, end: Long
    reader: GrammarReader

    init: func(=reader, =start, =end)

    print: func { "Token %s [%d, %d]: %s" printfln(class name, start, end, reader buffer[start..end]) }
}
