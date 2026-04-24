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
    var finding: FindingAPI {
        .init(
            report: self
        )
    }

    var patch: PatchAPI {
        .init(
            report: self
        )
    }

    var policy: PolicyAPI {
        .init(
            report: self
        )
    }

    struct FindingAPI: Sendable, Codable, Equatable, Hashable {
        public var report: PathExposureReport

        public init(
            report: PathExposureReport
        ) {
            self.report = report
        }

        public var required: [PathExposureFinding] {
            report.findings.filter {
                $0.action == .require_deny
            }
        }

        public var suggested: [PathExposureFinding] {
            report.findings.filter {
                $0.action == .suggest_deny
            }
        }

        public var warnings: [PathExposureFinding] {
            report.findings.filter {
                $0.action == .warn_only
            }
        }

        public var all: [PathExposureFinding] {
            report.findings
        }
    }

    struct PatchAPI: Sendable, Codable, Equatable, Hashable {
        public var report: PathExposureReport

        public init(
            report: PathExposureReport
        ) {
            self.report = report
        }

        public var required: PathAccessPolicyPatch {
            .prepending(
                report.finding.required
                    .compactMap(\.suggestedDenyRule)
                    .deduplicatedAccessRules()
            )
        }

        public var suggested: PathAccessPolicyPatch {
            .prepending(
                report.suggestions
                    .map(\.rule)
                    .deduplicatedAccessRules()
            )
        }

        public var suggestedFindings: PathAccessPolicyPatch {
            .prepending(
                report.finding.suggested
                    .compactMap(\.suggestedDenyRule)
                    .deduplicatedAccessRules()
            )
        }

        public var allFindings: PathAccessPolicyPatch {
            .prepending(
                report.finding.all
                    .compactMap(\.suggestedDenyRule)
                    .deduplicatedAccessRules()
            )
        }

        public func selected(
            _ suggestions: [PathDenySuggestion],
            includeRequired: Bool = true
        ) -> PathAccessPolicyPatch {
            let requiredRules = includeRequired
                ? required.prependRules
                : []

            return .prepending(
                (
                    requiredRules
                        + suggestions.map(\.rule)
                ).deduplicatedAccessRules()
            )
        }

        public func selected(
            ids: Set<String>,
            includeRequired: Bool = true
        ) -> PathAccessPolicyPatch {
            selected(
                report.suggestions.filtered(ids: ids),
                includeRequired: includeRequired
            )
        }

        public func selected(
            ids: [String],
            includeRequired: Bool = true
        ) -> PathAccessPolicyPatch {
            selected(
                ids: Set(ids),
                includeRequired: includeRequired
            )
        }
    }

    struct PolicyAPI: Sendable, Codable, Equatable, Hashable {
        public var report: PathExposureReport

        public init(
            report: PathExposureReport
        ) {
            self.report = report
        }

        public func applying(
            _ patch: PathAccessPolicyPatch,
            to base: PathAccessPolicy
        ) -> PathAccessPolicy {
            base.applying(patch)
        }

        public func required(
            from base: PathAccessPolicy
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.required
            )
        }

        public func suggested(
            from base: PathAccessPolicy
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.suggested
            )
        }

        public func suggestedFindings(
            from base: PathAccessPolicy
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.suggestedFindings
            )
        }

        public func allFindings(
            from base: PathAccessPolicy
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.allFindings
            )
        }

        public func selected(
            from base: PathAccessPolicy,
            suggestions: [PathDenySuggestion],
            includeRequired: Bool = true
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.selected(
                    suggestions,
                    includeRequired: includeRequired
                )
            )
        }

        public func selected(
            from base: PathAccessPolicy,
            ids: Set<String>,
            includeRequired: Bool = true
        ) -> PathAccessPolicy {
            base.applying(
                report.patch.selected(
                    ids: ids,
                    includeRequired: includeRequired
                )
            )
        }

        public func selected(
            from base: PathAccessPolicy,
            ids: [String],
            includeRequired: Bool = true
        ) -> PathAccessPolicy {
            selected(
                from: base,
                ids: Set(ids),
                includeRequired: includeRequired
            )
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
