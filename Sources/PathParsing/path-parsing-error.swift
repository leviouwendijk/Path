import Foundation
import Position

public enum PathParsingError: Error, LocalizedError, Sendable, Equatable {
    case empty(location: Position?)
    case invalidContentSelection(String, location: Position?)
    case unexpectedTrailingInput(String, location: Position?)
    case unterminatedQuotedPath(quote: Character, location: Position?)
    case invalidEscapeSequence(Character, location: Position?)

    public var errorDescription: String? {
        switch self {
        case .empty(let location?):
            return "Path expression cannot be empty at \(location.line):\(location.column)"

        case .empty(nil):
            return "Path expression cannot be empty"

        case .invalidContentSelection(let raw, let location?):
            return "Invalid content selection '\(raw)' at \(location.line):\(location.column)"

        case .invalidContentSelection(let raw, nil):
            return "Invalid content selection '\(raw)'"

        case .unexpectedTrailingInput(let raw, let location?):
            return "Unexpected trailing input '\(raw)' at \(location.line):\(location.column)"

        case .unexpectedTrailingInput(let raw, nil):
            return "Unexpected trailing input '\(raw)'"

        case .unterminatedQuotedPath(let quote, let location?):
            return "Unterminated quoted path starting with \(quote) at \(location.line):\(location.column)"

        case .unterminatedQuotedPath(let quote, nil):
            return "Unterminated quoted path starting with \(quote)"

        case .invalidEscapeSequence(let ch, let location?):
            return "Invalid escape sequence '\\\(ch)' at \(location.line):\(location.column)"

        case .invalidEscapeSequence(let ch, nil):
            return "Invalid escape sequence '\\\(ch)'"
        }
    }
}
