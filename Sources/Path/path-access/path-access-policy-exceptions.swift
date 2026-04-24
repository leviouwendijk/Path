public extension PathAccessPolicyPatch {
    static func exceptions(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        .prepending(
            patterns().map {
                .allow(
                    $0.matcher,
                    reason: $0.reason
                )
            }
        )
    }

    static func denials(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        .prepending(
            patterns().map {
                .deny(
                    $0.matcher,
                    reason: $0.reason
                )
            }
        )
    }
}

public extension PathAccessPolicy {
    func exceptions(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        applying(
            .exceptions(patterns)
        )
    }

    func denials(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        applying(
            .denials(patterns)
        )
    }
}

public extension PathAccessScope {
    func exceptions(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        applying(
            .exceptions(patterns)
        )
    }

    func denials(
        @PathAccessRulePatternBuilder _ patterns: () -> [PathAccessRulePattern]
    ) -> Self {
        applying(
            .denials(patterns)
        )
    }
}
