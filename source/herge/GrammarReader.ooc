import io/[File, Reader, StringReader]
import text/Regexp

GrammarReader: class extends StringReader {

    path: String

    init: func (=path) {
        super(File new(path) read())
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

}


