public enum PathExposureStatus: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case already_accessible
    case newly_accessible
}

public struct PathExposureEntry: Sendable, Codable, Equatable, Hashable {
    public var path: ScopedPath
    public var type: PathSegmentType
    public var baseline: PathAccessEvaluation
    public var proposed: PathAccessEvaluation
    public var status: PathExposureStatus

    public init(
        path: ScopedPath,
        type: PathSegmentType,
        baseline: PathAccessEvaluation,
        proposed: PathAccessEvaluation,
        status: PathExposureStatus
    ) {
        self.path = path
        self.type = type
        self.baseline = baseline
        self.proposed = proposed
        self.status = status
    }

    public var isNewlyAccessible: Bool {
        status == .newly_accessible
    }
}

public struct PathExposureFinding: Sendable, Codable, Equatable, Hashable {
    public var path: ScopedPath
    public var type: PathSegmentType
    public var status: PathExposureStatus
    public var matchedRuleIDs: [String]
    public var severity: PathSensitivitySeverity
    public var score: PathSensitivityScore
    public var reason: String
    public var action: PathSensitivityAction
    public var suggestedDenyRule: PathAccessRule?

    public init(
        path: ScopedPath,
        type: PathSegmentType,
        status: PathExposureStatus,
        matchedRuleIDs: [String],
        severity: PathSensitivitySeverity,
        score: PathSensitivityScore,
        reason: String,
        action: PathSensitivityAction,
        suggestedDenyRule: PathAccessRule? = nil
    ) {
        self.path = path
        self.type = type
        self.status = status
        self.matchedRuleIDs = matchedRuleIDs
        self.severity = severity
        self.score = score
        self.reason = reason
        self.action = action
        self.suggestedDenyRule = suggestedDenyRule
    }
}

public struct PathExposureGroup: Sendable, Codable, Equatable, Hashable {
    public var parentPath: ScopedPath?
    public var count: Int
    public var highestSeverity: PathSensitivitySeverity
    public var commonPatternSuggestion: PathDenySuggestion?
    public var findings: [PathExposureFinding]

    public init(
        parentPath: ScopedPath?,
        count: Int,
        highestSeverity: PathSensitivitySeverity,
        commonPatternSuggestion: PathDenySuggestion? = nil,
        findings: [PathExposureFinding]
    ) {
        self.parentPath = parentPath
        self.count = count
        self.highestSeverity = highestSeverity
        self.commonPatternSuggestion = commonPatternSuggestion
        self.findings = findings
    }
}

public struct PathExposureReport: Sendable, Codable, Equatable, Hashable {
    public var root: StandardPath
    public var scannedCount: Int
    public var baselineAccessibleCount: Int
    public var proposedAccessibleCount: Int
    public var newlyAccessibleCount: Int
    public var entries: [PathExposureEntry]
    public var findings: [PathExposureFinding]
    public var groups: [PathExposureGroup]
    public var suggestions: [PathDenySuggestion]
    public var truncated: Bool
    public var truncationReasons: [PathExposureTruncationReason]
    public var warnings: [String]
    public var configuration: PathExposureScanConfiguration

    public init(
        root: StandardPath,
        scannedCount: Int,
        baselineAccessibleCount: Int,
        proposedAccessibleCount: Int,
        newlyAccessibleCount: Int,
        entries: [PathExposureEntry],
        findings: [PathExposureFinding],
        groups: [PathExposureGroup],
        suggestions: [PathDenySuggestion],
        truncated: Bool,
        truncationReasons: [PathExposureTruncationReason],
        warnings: [String],
        configuration: PathExposureScanConfiguration
    ) {
        self.root = root
        self.scannedCount = scannedCount
        self.baselineAccessibleCount = baselineAccessibleCount
        self.proposedAccessibleCount = proposedAccessibleCount
        self.newlyAccessibleCount = newlyAccessibleCount
        self.entries = entries
        self.findings = findings
        self.groups = groups
        self.suggestions = suggestions
        self.truncated = truncated
        self.truncationReasons = truncationReasons
        self.warnings = warnings
        self.configuration = configuration
    }
}

public extension PathExposureReport {
    var requiredFindings: [PathExposureFinding] {
        findings.filter {
            $0.action == .require_deny
        }
    }

    var suggestedFindings: [PathExposureFinding] {
        findings.filter {
            $0.action == .suggest_deny
        }
    }

    var warningFindings: [PathExposureFinding] {
        findings.filter {
            $0.action == .warn_only
        }
    }

    var requiredPatch: PathAccessPolicyPatch {
        .prepending(
            requiredFindings
                .compactMap(\.suggestedDenyRule)
                .deduplicatedAccessRules()
        )
    }

    var suggestedPatch: PathAccessPolicyPatch {
        .prepending(
            suggestions
                .map(\.rule)
                .deduplicatedAccessRules()
        )
    }

    var suggestedFindingPatch: PathAccessPolicyPatch {
        .prepending(
            suggestedFindings
                .compactMap(\.suggestedDenyRule)
                .deduplicatedAccessRules()
        )
    }

    var allFindingPatch: PathAccessPolicyPatch {
        .prepending(
            findings
                .compactMap(\.suggestedDenyRule)
                .deduplicatedAccessRules()
        )
    }

    func patch(
        for suggestions: [PathDenySuggestion],
        includeRequiredFindings: Bool = true
    ) -> PathAccessPolicyPatch {
        let requiredRules = includeRequiredFindings
            ? requiredPatch.prependRules
            : []

        return .prepending(
            (
                requiredRules
                    + suggestions.map(\.rule)
            ).deduplicatedAccessRules()
        )
    }

    func patch(
        forSuggestionIDs ids: Set<String>,
        includeRequiredFindings: Bool = true
    ) -> PathAccessPolicyPatch {
        patch(
            for: suggestions.filtered(ids: ids),
            includeRequiredFindings: includeRequiredFindings
        )
    }

    func policy(
        byApplying patch: PathAccessPolicyPatch,
        to base: PathAccessPolicy
    ) -> PathAccessPolicy {
        base.applying(patch)
    }

    func policyWithRequiredDenials(
        from base: PathAccessPolicy
    ) -> PathAccessPolicy {
        base.applying(requiredPatch)
    }

    func policyWithSuggestedDenials(
        from base: PathAccessPolicy
    ) -> PathAccessPolicy {
        base.applying(suggestedPatch)
    }

    func policy(
        from base: PathAccessPolicy,
        selectedSuggestionIDs ids: Set<String>,
        includeRequiredFindings: Bool = true
    ) -> PathAccessPolicy {
        base.applying(
            patch(
                forSuggestionIDs: ids,
                includeRequiredFindings: includeRequiredFindings
            )
        )
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
