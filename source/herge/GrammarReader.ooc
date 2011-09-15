import io/[Reader, StringReader]
import structs/ArrayList
import text/Regexp

GrammarReader: class extends StringReader {

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
        "Parsing error at %d: %s" printfln(marker, message)
        exit(1)
    }

}


