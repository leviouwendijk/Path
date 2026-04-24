import Foundation

public enum PathTreeLookupError: Error, LocalizedError, Sendable, Equatable {
    case nodeNotFound(
        StandardPath,
        expected: PathSegmentType?
    )

    case nodeTypeMismatch(
        StandardPath,
        expected: PathSegmentType?,
        actual: PathSegmentType
    )

    public var errorDescription: String? {
        switch self {
        case .nodeNotFound(let path, let expected):
            return """
            Path tree node not found: \
            \(path.render(as: .relative, filetype: true)) \
            expected=\(expected?.rawValue ?? "any")
            """

        case .nodeTypeMismatch(let path, let expected, let actual):
            return """
            Path tree node type mismatch: \
            \(path.render(as: .relative, filetype: true)) \
            expected=\(expected?.rawValue ?? "any") actual=\(actual.rawValue)
            """
        }
    }
}
