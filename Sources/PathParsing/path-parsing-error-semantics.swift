import Errors
import Foundation

extension PathParsingError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.parsing"

    public var errorCode: String {
        switch self {
        case .empty: return "empty"
        case .invalidContentSelection: return "invalid_content_selection"
        case .unexpectedTrailingInput: return "unexpected_trailing_input"
        case .unterminatedQuotedPath: return "unterminated_quoted_path"
        case .invalidEscapeSequence: return "invalid_escape_sequence"
        }
    }

    public var errorDisposition: ErrorDisposition? { .invalid_input }
}
