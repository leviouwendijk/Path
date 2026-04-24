public enum PathDenySuggestionKind: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case exact_path
    case basename
    case suffix
    case component
    case parent
    case expression
}

public enum PathDenySuggestionConfidence: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case low
    case medium
    case high
}

public struct PathDenySuggestionScore: Sendable, Codable, Equatable, Hashable, Comparable, CustomStringConvertible {
    public var value: Int
    public var components: [PathSensitivityScoreComponent]

    public init(
        value: Int,
        components: [PathSensitivityScoreComponent] = []
    ) {
        self.value = value
        self.components = components
    }

    public static let zero = Self(
        value: 0
    )

    public var description: String {
        "\(value)"
    }

    public func adding(
        value: Int,
        name: String,
        detail: String? = nil
    ) -> Self {
        .init(
            value: self.value + value,
            components: components + [
                .init(
                    name: name,
                    value: value,
                    detail: detail,
                    source: .path
                )
            ]
        )
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.value < rhs.value
    }
}

public struct PathDenySuggestion: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var kind: PathDenySuggestionKind
    public var rule: PathAccessRule
    public var coverageCount: Int
    public var collateralCount: Int
    public var collateralExamples: [ScopedPath]
    public var confidence: PathDenySuggestionConfidence
    public var score: PathDenySuggestionScore
    public var reason: String

    public init(
        kind: PathDenySuggestionKind,
        rule: PathAccessRule,
        coverageCount: Int,
        collateralCount: Int,
        collateralExamples: [ScopedPath] = [],
        confidence: PathDenySuggestionConfidence,
        score: PathDenySuggestionScore,
        reason: String
    ) {
        self.kind = kind
        self.rule = rule
        self.coverageCount = coverageCount
        self.collateralCount = collateralCount
        self.collateralExamples = collateralExamples
        self.confidence = confidence
        self.score = score
        self.reason = reason
    }

    public var id: String {
        "\(kind.rawValue):\(rule.matcher.summary)"
    }

    public var patch: PathAccessPolicyPatch {
        .prepending(
            [
                rule
            ]
        )
    }
}

public extension Sequence where Element == PathDenySuggestion {
    var patch: PathAccessPolicyPatch {
        .prepending(
            map(\.rule).deduplicatedAccessRules()
        )
    }
}

public extension Array where Element == PathDenySuggestion {
    func filtered(
        ids: Set<String>
    ) -> [PathDenySuggestion] {
        filter {
            ids.contains($0.id)
        }
    }
}

private extension Array where Element == PathAccessRule {
    func deduplicatedAccessRules() -> [PathAccessRule] {
        var seen = Set<String>()
        var out: [PathAccessRule] = []

        for rule in self {
            let key = rule.matcher.summary

            guard seen.insert(key).inserted else {
                continue
            }

            out.append(rule)
        }

        return out
    }
}
