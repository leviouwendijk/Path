public struct PathAccessPolicyPatch: Sendable, Codable, Equatable, Hashable {
    public var prependRules: [PathAccessRule]
    public var appendRules: [PathAccessRule]

    public init(
        prependRules: [PathAccessRule] = [],
        appendRules: [PathAccessRule] = []
    ) {
        self.prependRules = prependRules
        self.appendRules = appendRules
    }

    public static let empty = Self()
}

public extension PathAccessPolicyPatch {
    var isEmpty: Bool {
        prependRules.isEmpty && appendRules.isEmpty
    }

    static func prepending(
        _ rules: [PathAccessRule]
    ) -> Self {
        .init(
            prependRules: rules
        )
    }

    static func appending(
        _ rules: [PathAccessRule]
    ) -> Self {
        .init(
            appendRules: rules
        )
    }
}

public extension PathAccessPolicy {
    func applying(
        _ patch: PathAccessPolicyPatch
    ) -> Self {
        .init(
            rules: patch.prependRules + rules + patch.appendRules,
            default: `default`
        )
    }

    func prepending(
        _ patch: PathAccessPolicyPatch
    ) -> Self {
        applying(patch)
    }
}
