public enum TextFile: String, FileType {
    case txt
    case md
    case norg

    // markup-ish “text”
    case html
    case xml

    // common configs
    case yaml
    case yml
    case json
    case toml
    case ini
    case conf
    case env

    // styles
    case css
    case scss
    case sass
    case less

    // office-ish “text”
    case doc
    case docx
    case rtf
    case odt
}
