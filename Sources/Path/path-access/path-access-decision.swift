public enum PathAccessDecision: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case allow
    case deny
}

public extension PathAccessDecision {
    var isAllowed: Bool {
        self == .allow
    }

    var isDenied: Bool {
        self == .deny
    }
}
