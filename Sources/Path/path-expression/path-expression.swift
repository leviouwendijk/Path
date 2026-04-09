import Foundation

public struct PathExpression: Sendable, Codable, Equatable {
    public var anchor: PathExpressionAnchor
    public var pattern: PathPattern

    public init(
        anchor: PathExpressionAnchor = .relative,
        pattern: PathPattern
    ) {
        self.anchor = anchor
        self.pattern = pattern
    }
}

public extension PathExpression {
    var terminalHint: PathTerminalHint {
        pattern.terminalHint
    }

    var containsPatternSyntax: Bool {
        pattern.containsPatternSyntax
    }

    var staticPrefix: StandardPath {
        pattern.staticPrefix()
    }

    func scanRoot(
        relativeTo anchor: PathAnchor = .cwd
    ) -> URL {
        let base = self.anchor
            .resolved(relativeTo: anchor)
            .directory_url

        return staticPrefix
            .url(base: base, filetype: false)
            .standardizedFileURL
    }
}

public extension PathExpression {
    var scanPattern: PathPattern {
        pattern.suffixAfterStaticPrefix()
    }

    func resolvedAnchor(
        relativeTo anchor: PathAnchor = .cwd
    ) -> PathAnchor {
        self.anchor.resolved(relativeTo: anchor)
    }
}
