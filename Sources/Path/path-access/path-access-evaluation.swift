public struct PathAccessEvaluation: Sendable, Codable, Equatable, Hashable {
    public let path: ScopedPath
    public let type: PathSegmentType?
    public let decision: PathAccessDecision
    public let matchedRule: PathAccessRule?

    public init(
        path: ScopedPath,
        type: PathSegmentType?,
        decision: PathAccessDecision,
        matchedRule: PathAccessRule?
    ) {
        self.path = path
        self.type = type
        self.decision = decision
        self.matchedRule = matchedRule
    }

    public var isAllowed: Bool {
        decision.isAllowed
    }

    public var isDenied: Bool {
        decision.isDenied
    }
}
