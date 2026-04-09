import Foundation
import Parsing
import Path

public struct PathExpressionParser: Parser, Sendable {
    public typealias Output = PathExpression

    public init() {}

    public func parse(
        _ cursor: Cursor
    ) -> ParseResult<PathExpression> {
        var cur = cursor
        let start = cur.mark()

        do {
            let output = try Self.parseExpression(&cur)
            PathParsingCore.consumeTrailingTrivia(&cur)

            return .success(
                output,
                cur
            )
        } catch let error as PathParsingError {
            return .failure(
                Diagnostic(
                    error.localizedDescription,
                    range: cur.range(from: start)
                )
            )
        } catch {
            return .failure(
                Diagnostic(
                    "Path expression parse failed: \(error.localizedDescription)",
                    range: cur.range(from: start)
                )
            )
        }
    }

    public static func parse(
        _ input: String
    ) throws -> PathExpression {
        var cur = Cursor(input)
        let output = try parseExpression(&cur)

        PathParsingCore.consumeTrailingTrivia(&cur)

        if cur.peek() != nil {
            let mark = cur.mark()

            throw PathParsingError.unexpectedTrailingInput(
                String(cur.slice(from: mark)),
                location: PathParsingCore.loc(
                    in: input,
                    offset: cur.offset
                )
            )
        }

        return output
    }
}

private extension PathExpressionParser {
    static func parseExpression(
        _ cursor: inout Cursor
    ) throws -> PathExpression {
        let input = cursor.input
        let token = try PathParsingCore.readPathToken(
            &cursor,
            allowQuotedSelectionSuffix: false
        )

        guard !token.raw.isEmpty else {
            throw PathParsingError.empty(
                location: PathParsingCore.loc(
                    in: input,
                    offset: token.startOffset
                )
            )
        }

        var working = token.raw
        var anchor: PathExpressionAnchor = .relative
        var terminalHint: PathTerminalHint = .unspecified

        if working == "/" {
            return PathExpression(
                anchor: .root,
                pattern: PathPattern(
                    [],
                    terminalHint: .directory
                )
            )
        }

        if working == "~" || working == "$HOME" {
            return PathExpression(
                anchor: .home,
                pattern: PathPattern(
                    [],
                    terminalHint: .directory
                )
            )
        }

        if working == "$CWD" {
            return PathExpression(
                anchor: .cwd,
                pattern: PathPattern(
                    [],
                    terminalHint: .directory
                )
            )
        }

        if working.hasSuffix("/") {
            terminalHint = .directory
            working.removeLast()
        }

        if working.hasPrefix("~/") {
            anchor = .home
            working.removeFirst(2)
        } else if working.hasPrefix("$HOME/") {
            anchor = .home
            working.removeFirst("$HOME/".count)
        } else if working.hasPrefix("$CWD/") {
            anchor = .cwd
            working.removeFirst("$CWD/".count)
        } else if working.hasPrefix("/") {
            anchor = .root
            working.removeFirst()
        }

        let components: [PathPatternComponent]

        if working.isEmpty {
            components = []
        } else {
            components = working
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
                .map(PathPatternComponent.interpreting)
        }

        return PathExpression(
            anchor: anchor,
            pattern: PathPattern(
                components,
                terminalHint: terminalHint
            )
        )
    }
}
