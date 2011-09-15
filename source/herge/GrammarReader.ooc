import io/[Reader, StringReader]
import structs/ArrayList
import text/Regexp

GrammarReader: class extends StringReader {

    line := Regexp compile(".*")

    init: func (string: String) {
        super(string)
    }

    readRegexp: func (r: Regexp) -> String {
        _match := r matches(string, marker, string size)
        if(_match) {
            sub := _match group(0)
            marker += sub length() 
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

        "Parsing error at %d: %s\n> %s\n  %s" printfln(marker, message, line, " " times(errorMarker - startOfLine) + "~")
        exit(1)
    }

}


