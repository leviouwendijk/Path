public struct PathAccessRule: Sendable, Codable, Equatable, Hashable {
    public var decision: PathAccessDecision
    public var matcher: PathAccessMatcher
    public var reason: String?

    public init(
        decision: PathAccessDecision,
        matcher: PathAccessMatcher,
        reason: String? = nil
    ) {
        self.decision = decision
        self.matcher = matcher
        self.reason = reason
    }

    func matches(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        matcher.matches(
            path,
            type: type
        )
    }
}

public extension PathAccessRule {
    static func allow(
        _ matcher: PathAccessMatcher,
        reason: String? = nil
    ) -> Self {
        .init(
            decision: .allow,
            matcher: matcher,
            reason: reason
        )
    }

    static func deny(
        _ matcher: PathAccessMatcher,
        reason: String? = nil
    ) -> Self {
        .init(
            decision: .deny,
            matcher: matcher,
            reason: reason
        )
    }

    static func allowComponent(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        allow(
            .component(value),
            reason: reason
        )
    }

    static func denyComponent(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        deny(
            .component(value),
            reason: reason
        )
    }

    static func allowBasename(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        allow(
            .basename(value),
            reason: reason
        )
    }

    static func denyBasename(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        deny(
            .basename(value),
            reason: reason
        )
    }

    static func allowSuffix(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        allow(
            .suffix(value),
            reason: reason
        )
    }

    static func denySuffix(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        deny(
            .suffix(value),
            reason: reason
        )
    }

    static func allowExpression(
        _ value: PathExpression,
        reason: String? = nil
    ) -> Self {
        allow(
            .expression(value),
            reason: reason
        )
    }

    static func denyExpression(
        _ value: PathExpression,
        reason: String? = nil
    ) -> Self {
        deny(
            .expression(value),
            reason: reason
        )
    }
}
