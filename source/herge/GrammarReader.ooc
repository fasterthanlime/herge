import io/[Reader, StringReader]
import structs/ArrayList
import text/Regexp
import Token

GrammarReader: class extends StringReader {

    line := Regexp compile(".*")

    init: func (string: String) {
        super(string)
    }

    emptyToken: func -> Token {
        Token new(this, marker, marker)
    }

    readRegexp: func (r: Regexp, groupIndex := 0) -> String {
        _match := r matches(string, marker, string size)
        if(_match && _match groupStart(0) == marker) {
            sub := _match group(groupIndex)
            marker += _match groupLength(0)
            sub
        } else {
            ""
        }
    }

    readCommaList: func -> ArrayList<String> {
        list := ArrayList<String> new() 
        while(hasNext?()) {
            word := readUntil(',')
            list add(word trim())
        }
        list
    }

    error: func (message: String) {
        errorMarker := marker
        while(peek() != '\n' && marker > 0) rewind(1)
        read()

        startOfLine := marker 

        line := readLine()

        "Parsing error at %d: %s\n> %s\n  %s" printfln(errorMarker, message, line, " " times(errorMarker - startOfLine) + "~")
        exit(1)
    }

}


