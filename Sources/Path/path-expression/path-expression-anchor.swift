import Foundation

public enum PathExpressionAnchor: String, Sendable, Codable, Equatable {
    case relative
    case root
    case home
    case cwd
}

public extension PathExpressionAnchor {
    func resolved(
        relativeTo anchor: PathAnchor = .cwd
    ) -> PathAnchor {
        switch self {
        case .relative:
            return anchor

        case .root:
            return .root

        case .home:
            return .home

        case .cwd:
            return .cwd
        }
    }
}
