public struct PathPattern: Sendable, Codable, Equatable {
    public var components: [PathPatternComponent]
    public var terminalHint: PathTerminalHint

    public init(
        _ components: [PathPatternComponent],
        terminalHint: PathTerminalHint = .unspecified
    ) {
        self.components = components
        self.terminalHint = terminalHint
    }

    public init(
        _ components: PathPatternComponent...,
        terminalHint: PathTerminalHint = .unspecified
    ) {
        self.init(
            components,
            terminalHint: terminalHint
        )
    }

    public var isConcrete: Bool {
        components.allSatisfy(\.isConcrete)
    }

    public var requiresRecursiveTraversal: Bool {
        components.contains {
            if case .recursive = $0 {
                return true
            }

            return false
        }
    }

    public func staticPrefix() -> StandardPath {
        StandardPath(staticPrefixStrings)
    }
}

public extension PathPattern {
    var staticPrefixStrings: [String] {
        var out: [String] = []

        for component in components {
            guard case .literal(let value) = component else {
                break
            }

            out.append(value)
        }

        return out
    }

    init(
        interpreting raw: [String],
        terminalHint: PathTerminalHint = .unspecified
    ) {
        self.init(
            raw.map(PathPatternComponent.interpreting),
            terminalHint: terminalHint
        )
    }

    init(
        interpreting raw: String...,
        terminalHint: PathTerminalHint = .unspecified
    ) {
        self.init(
            interpreting: raw,
            terminalHint: terminalHint
        )
    }

    var containsPatternSyntax: Bool {
        components.contains {
            switch $0 {
            case .literal:
                return false

            case .any,
                 .recursive,
                 .componentPattern:
                return true
            }
        }
    }
}

public extension PathPattern {
    var staticPrefixCount: Int {
        staticPrefixStrings.count
    }

    func suffixAfterStaticPrefix() -> PathPattern {
        PathPattern(
            Array(components.dropFirst(staticPrefixCount)),
            terminalHint: terminalHint
        )
    }
}
