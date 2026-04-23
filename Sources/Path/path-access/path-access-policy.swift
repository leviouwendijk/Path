public struct PathAccessPolicy: Sendable, Codable, Equatable, Hashable {
    public var rules: [PathAccessRule]
    public var defaultDecision: PathAccessDecision

    public init(
        rules: [PathAccessRule] = [],
        defaultDecision: PathAccessDecision = .allow
    ) {
        self.rules = rules
        self.defaultDecision = defaultDecision
    }

    public static let allowAll = Self()
}

public extension PathAccessPolicy {
    func evaluate(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> PathAccessEvaluation {
        for rule in rules {
            if rule.matches(
                path,
                type: type
            ) {
                return .init(
                    path: path,
                    type: type,
                    decision: rule.decision,
                    matchedRule: rule
                )
            }
        }

        return .init(
            path: path,
            type: type,
            decision: defaultDecision,
            matchedRule: nil
        )
    }

    func allows(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        evaluate(
            path,
            type: type
        ).isAllowed
    }

    func denies(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        !allows(
            path,
            type: type
        )
    }

    func prepending(
        _ rules: [PathAccessRule]
    ) -> Self {
        .init(
            rules: rules + self.rules,
            defaultDecision: defaultDecision
        )
    }

    func appending(
        _ rules: [PathAccessRule]
    ) -> Self {
        .init(
            rules: self.rules + rules,
            defaultDecision: defaultDecision
        )
    }
}
