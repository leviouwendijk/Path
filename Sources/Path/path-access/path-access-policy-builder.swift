@resultBuilder
public enum PathAccessPolicyBuilder {
    public static func buildBlock(
        _ components: [PathAccessRule]...
    ) -> [PathAccessRule] {
        components.flatMap {
            $0
        }
    }

    public static func buildExpression(
        _ expression: PathAccessRule
    ) -> [PathAccessRule] {
        [
            expression
        ]
    }

    public static func buildExpression(
        _ expression: [PathAccessRule]
    ) -> [PathAccessRule] {
        expression
    }

    public static func buildOptional(
        _ component: [PathAccessRule]?
    ) -> [PathAccessRule] {
        component ?? []
    }

    public static func buildEither(
        first component: [PathAccessRule]
    ) -> [PathAccessRule] {
        component
    }

    public static func buildEither(
        second component: [PathAccessRule]
    ) -> [PathAccessRule] {
        component
    }

    public static func buildArray(
        _ components: [[PathAccessRule]]
    ) -> [PathAccessRule] {
        components.flatMap {
            $0
        }
    }

    public static func buildLimitedAvailability(
        _ component: [PathAccessRule]
    ) -> [PathAccessRule] {
        component
    }
}

@resultBuilder
public enum PathAccessRulePatternBuilder {
    public static func buildBlock(
        _ components: [PathAccessRulePattern]...
    ) -> [PathAccessRulePattern] {
        components.flatMap {
            $0
        }
    }

    public static func buildExpression(
        _ expression: PathAccessRulePattern
    ) -> [PathAccessRulePattern] {
        [
            expression
        ]
    }

    public static func buildExpression(
        _ expression: PathAccessMatcher
    ) -> [PathAccessRulePattern] {
        [
            .init(
                matcher: expression
            )
        ]
    }

    public static func buildExpression(
        _ expression: [PathAccessRulePattern]
    ) -> [PathAccessRulePattern] {
        expression
    }

    public static func buildOptional(
        _ component: [PathAccessRulePattern]?
    ) -> [PathAccessRulePattern] {
        component ?? []
    }

    public static func buildEither(
        first component: [PathAccessRulePattern]
    ) -> [PathAccessRulePattern] {
        component
    }

    public static func buildEither(
        second component: [PathAccessRulePattern]
    ) -> [PathAccessRulePattern] {
        component
    }

    public static func buildArray(
        _ components: [[PathAccessRulePattern]]
    ) -> [PathAccessRulePattern] {
        components.flatMap {
            $0
        }
    }

    public static func buildLimitedAvailability(
        _ component: [PathAccessRulePattern]
    ) -> [PathAccessRulePattern] {
        component
    }
}

public struct PathAccessRulePattern: Sendable, Codable, Equatable, Hashable {
    public var matcher: PathAccessMatcher
    public var reason: String?

    public init(
        matcher: PathAccessMatcher,
        reason: String? = nil
    ) {
        self.matcher = matcher
        self.reason = reason
    }
}

public extension PathAccessRulePattern {
    static func component(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        .init(
            matcher: .component(value),
            reason: reason
        )
    }

    static func basename(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        .init(
            matcher: .basename(value),
            reason: reason
        )
    }

    static func suffix(
        _ value: String,
        reason: String? = nil
    ) -> Self {
        .init(
            matcher: .suffix(value),
            reason: reason
        )
    }

    static func expression(
        _ value: PathExpression,
        reason: String? = nil
    ) -> Self {
        .init(
            matcher: .expression(value),
            reason: reason
        )
    }
}

public extension PathAccessPolicy {
    init(
        `default`: PathAccessDecision = .allow,
        @PathAccessPolicyBuilder rules: () -> [PathAccessRule]
    ) {
        self.init(
            rules: rules(),
            default: `default`
        )
    }
}

public func allow(
    @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
) -> [PathAccessRule] {
    patterns().map {
        .allow(
            $0.matcher,
            reason: $0.reason
        )
    }
}

public func deny(
    @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
) -> [PathAccessRule] {
    patterns().map {
        .deny(
            $0.matcher,
            reason: $0.reason
        )
    }
}

public func component(
    _ value: String,
    reason: String? = nil
) -> PathAccessRulePattern {
    .component(
        value,
        reason: reason
    )
}

public func basename(
    _ value: String,
    reason: String? = nil
) -> PathAccessRulePattern {
    .basename(
        value,
        reason: reason
    )
}

public func suffix(
    _ value: String,
    reason: String? = nil
) -> PathAccessRulePattern {
    .suffix(
        value,
        reason: reason
    )
}

public func expression(
    _ value: PathExpression,
    reason: String? = nil
) -> PathAccessRulePattern {
    .expression(
        value,
        reason: reason
    )
}

public func components(
    _ values: [String],
    reason: String? = nil
) -> [PathAccessRulePattern] {
    values.map {
        .component(
            $0,
            reason: reason
        )
    }
}

public func components(
    _ values: String...,
    reason: String? = nil
) -> [PathAccessRulePattern] {
    components(
        values,
        reason: reason
    )
}

public func basenames(
    _ values: [String],
    reason: String? = nil
) -> [PathAccessRulePattern] {
    values.map {
        .basename(
            $0,
            reason: reason
        )
    }
}

public func basenames(
    _ values: String...,
    reason: String? = nil
) -> [PathAccessRulePattern] {
    basenames(
        values,
        reason: reason
    )
}

public func suffixes(
    _ values: [String],
    reason: String? = nil
) -> [PathAccessRulePattern] {
    values.map {
        .suffix(
            $0,
            reason: reason
        )
    }
}

public func suffixes(
    _ values: String...,
    reason: String? = nil
) -> [PathAccessRulePattern] {
    suffixes(
        values,
        reason: reason
    )
}

public func expressions(
    _ values: [PathExpression],
    reason: String? = nil
) -> [PathAccessRulePattern] {
    values.map {
        .expression(
            $0,
            reason: reason
        )
    }
}

public func expressions(
    _ values: PathExpression...,
    reason: String? = nil
) -> [PathAccessRulePattern] {
    expressions(
        values,
        reason: reason
    )
}
