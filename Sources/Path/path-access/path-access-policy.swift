public struct PathAccessPolicy: Sendable, Codable, Equatable, Hashable {
    public var rules: [PathAccessRule]
    public var `default`: PathAccessDecision

    public init(
        rules: [PathAccessRule] = [],
        `default`: PathAccessDecision = .allow
    ) {
        self.rules = rules
        self.`default` = `default`
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
            decision: `default`,
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
            default: `default`
        )
    }

    func appending(
        _ rules: [PathAccessRule]
    ) -> Self {
        .init(
            rules: self.rules + rules,
            default: `default`
        )
    }
}
