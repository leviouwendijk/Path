public enum PathPatternComponent: Sendable, Codable, Equatable, ExpressibleByStringLiteral {
    case literal(String)
    case any
    case recursive
    case componentPattern(String)

    public init(stringLiteral value: StringLiteralType) {
        self = Self.interpreting(value)
    }

    public static func interpreting(
        _ raw: String
    ) -> Self {
        switch raw {
        case "*":
            return .any

        case "**":
            return .recursive

        default:
            if raw.contains("*")
                || raw.contains("?")
                || raw.contains("[")
            {
                return .componentPattern(raw)
            }

            return .literal(raw)
        }
    }

    public var isConcrete: Bool {
        switch self {
        case .literal:
            return true

        case .any,
             .recursive,
             .componentPattern:
            return false
        }
    }
}
