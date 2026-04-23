import Foundation
import Parsing
import Position

public enum PathParsingCore {
    public struct ScannedPathToken: Sendable, Equatable {
        let raw: String
        let startOffset: Int
        let wasQuoted: Bool
        let quotedSelectionSuffix: String?
        let quotedSelectionOffset: Int?
    }

    @inline(__always)
    public static func isWhitespace(
        _ ch: Character
    ) -> Bool {
        ch == " " || ch == "\t" || ch == "\n" || ch == "\r"
    }

    @inline(__always)
    public static func isExpressionBoundary(
        _ ch: Character
    ) -> Bool {
        isWhitespace(ch)
            || ch == ","
            || ch == ";"
            || ch == ")"
            || ch == "}"
    }

    public static func loc(
        in input: String,
        offset: Int
    ) -> Position? {
        var line = 1
        var column = 1
        var i = 0

        for ch in input {
            if i >= offset {
                break
            }

            if ch == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }

            i += 1
        }

        return Position(
            uncheckedFile: nil,
            line: line,
            column: column,
            invocation: nil
        )
    }
}

extension PathParsingCore {
    public static func consumeWhitespace(
        _ cursor: inout Cursor
    ) {
        while let ch = cursor.peek(), isWhitespace(ch) {
            cursor.advance()
        }
    }

    public static func consumeTrivia(
        _ cursor: inout Cursor
    ) {
        while true {
            let before = cursor.offset

            consumeWhitespace(&cursor)

            if consumeLineComment(&cursor) {
                continue
            }

            if cursor.offset == before {
                return
            }
        }
    }

    public static func consumeTrailingTrivia(
        _ cursor: inout Cursor
    ) {
        consumeTrivia(&cursor)
    }

    public static func consumeLineComment(
        _ cursor: inout Cursor
    ) -> Bool {
        guard let ch = cursor.peek() else {
            return false
        }

        if ch == "#" {
            cursor.advance()

            while let next = cursor.peek(),
                  next != "\n",
                  next != "\r"
            {
                cursor.advance()
            }

            return true
        }

        if ch == "/" {
            var lookahead = cursor
            lookahead.advance()

            if lookahead.peek() == "/" {
                cursor = lookahead
                cursor.advance()

                while let next = cursor.peek(),
                      next != "\n",
                      next != "\r"
                {
                    cursor.advance()
                }

                return true
            }
        }

        return false
    }

    public static func readPathToken(
        _ cursor: inout Cursor,
        allowQuotedSelectionSuffix: Bool
    ) throws -> ScannedPathToken {
        consumeTrivia(&cursor)

        let startOffset = cursor.offset

        guard let first = cursor.peek() else {
            return .init(
                raw: "",
                startOffset: startOffset,
                wasQuoted: false,
                quotedSelectionSuffix: nil,
                quotedSelectionOffset: nil
            )
        }

        if first == "\"" || first == "'" {
            let raw = try readQuotedPath(&cursor)

            var suffix: String? = nil
            var suffixOffset: Int? = nil

            if allowQuotedSelectionSuffix,
               cursor.peek() == "["
            {
                suffixOffset = cursor.offset
                suffix = readBracketSuffix(&cursor)
            }

            return .init(
                raw: raw,
                startOffset: startOffset,
                wasQuoted: true,
                quotedSelectionSuffix: suffix,
                quotedSelectionOffset: suffixOffset
            )
        }

        var raw = ""

        while let ch = cursor.peek(),
              !isExpressionBoundary(ch)
        {
            raw.append(ch)
            cursor.advance()
        }

        return .init(
            raw: raw,
            startOffset: startOffset,
            wasQuoted: false,
            quotedSelectionSuffix: nil,
            quotedSelectionOffset: nil
        )
    }

    public static func readQuotedPath(
        _ cursor: inout Cursor
    ) throws -> String {
        guard let quote = cursor.peek(),
              quote == "\"" || quote == "'" else {
            return ""
        }

        let input = cursor.input
        let openingOffset = cursor.offset

        cursor.advance()

        var output = ""

        while let ch = cursor.peek() {
            if ch == quote {
                cursor.advance()
                return output
            }

            if ch == "\\" {
                cursor.advance()

                guard let escaped = cursor.peek() else {
                    throw PathParsingError.unterminatedQuotedPath(
                        quote: quote,
                        location: loc(
                            in: input,
                            offset: openingOffset
                        )
                    )
                }

                switch escaped {
                case "\\": output.append("\\")
                case "\"": output.append("\"")
                case "'":  output.append("'")
                case "n":  output.append("\n")
                case "r":  output.append("\r")
                case "t":  output.append("\t")

                default:
                    throw PathParsingError.invalidEscapeSequence(
                        escaped,
                        location: loc(
                            in: input,
                            offset: cursor.offset
                        )
                    )
                }

                cursor.advance()
                continue
            }

            output.append(ch)
            cursor.advance()
        }

        throw PathParsingError.unterminatedQuotedPath(
            quote: quote,
            location: loc(
                in: input,
                offset: openingOffset
            )
        )
    }

    public static func readBracketSuffix(
        _ cursor: inout Cursor
    ) -> String {
        guard cursor.peek() == "[" else {
            return ""
        }

        var raw = ""
        var depth = 0

        while let ch = cursor.peek() {
            if depth == 0, isExpressionBoundary(ch) {
                break
            }

            raw.append(ch)
            cursor.advance()

            if ch == "[" {
                depth += 1
            } else if ch == "]" {
                depth -= 1

                if depth <= 0 {
                    break
                }
            }
        }

        return raw
    }
}
