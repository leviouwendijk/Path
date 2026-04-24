import Foundation

public enum PathExposureScan {
    public static func scan(
        _ specification: PathExposureScanSpecification
    ) throws -> PathExposureReport {
        let root = PathNormalization.root(
            specification.root
        )
        let sandbox = try PathSandbox(
            root: root
        )

        let result = try PathScan.scan(
            fullTreeSpecification(),
            relativeTo: .directoryPath(root),
            configuration: specification.configuration.walkConfiguration
        )

        var entries = exposureEntries(
            from: result,
            root: root,
            sandbox: sandbox,
            specification: specification
        )

        var truncationReasons: [PathExposureTruncationReason] = []

        if let maxEntries = specification.configuration.maxEntries,
           maxEntries >= 0,
           entries.count > maxEntries {
            entries = Array(
                entries.prefix(maxEntries)
            )
            truncationReasons.append(.max_entries)
        }

        var findings = entries.compactMap {
            finding(
                for: $0,
                profile: specification.sensitivity
            )
        }

        if let maxFindings = specification.configuration.maxFindings,
           maxFindings >= 0,
           findings.count > maxFindings {
            findings = Array(
                findings.prefix(maxFindings)
            )
            truncationReasons.append(.max_findings)
        }

        let suggestions = PathDenySuggestionBuilder.suggestions(
            findings: findings,
            entries: entries,
            configuration: specification.configuration
        )

        let groups = groupedFindings(
            findings,
            entries: entries,
            configuration: specification.configuration
        )

        return .init(
            root: root,
            scannedCount: result.matches.count,
            baselineAccessibleCount: entries.filter {
                $0.baseline.isAllowed
            }.count,
            proposedAccessibleCount: entries.count,
            newlyAccessibleCount: entries.filter(\.isNewlyAccessible).count,
            entries: entries,
            findings: findings,
            groups: groups,
            suggestions: suggestions,
            truncated: !truncationReasons.isEmpty,
            truncationReasons: truncationReasons,
            warnings: result.warnings.map {
                String(describing: $0)
            },
            configuration: specification.configuration
        )
    }
}

private extension PathExposureScan {
    static func fullTreeSpecification() -> PathScanSpecification {
        .init(
            includes: [
                PathExpression(
                    pattern: PathPattern(
                        [
                            .recursive
                        ]
                    )
                )
            ]
        )
    }

    static func exposureEntries(
        from result: PathScanResult,
        root: StandardPath,
        sandbox: PathSandbox,
        specification: PathExposureScanSpecification
    ) -> [PathExposureEntry] {
        result.matches.compactMap { match in
            guard let relative = sandbox.tree.relative(
                match.path
            ) else {
                return nil
            }

            guard !relative.segments.isEmpty else {
                return nil
            }

            let scoped = ScopedPath(
                root: root,
                relative: relative
            )
            let baseline = specification.baselinePolicy.evaluate(
                scoped,
                type: match.type
            )
            let proposed = specification.proposedPolicy.evaluate(
                scoped,
                type: match.type
            )

            guard proposed.isAllowed else {
                return nil
            }

            return .init(
                path: scoped,
                type: match.type,
                baseline: baseline,
                proposed: proposed,
                status: baseline.isAllowed
                    ? .already_accessible
                    : .newly_accessible
            )
        }
    }

    static func finding(
        for entry: PathExposureEntry,
        profile: PathSensitivityProfile
    ) -> PathExposureFinding? {
        let matchedRules = profile.matchedRules(
            for: entry.path,
            type: entry.type
        )

        guard !matchedRules.isEmpty else {
            return nil
        }

        var score = PathSensitivityScore.zero

        for rule in matchedRules {
            score = score.adding(
                rule.scoreComponent()
            )
        }

        if entry.path.hasHiddenComponent {
            score = score.adding(
                value: 15,
                name: "hidden_path",
                detail: "Path contains at least one hidden component."
            )
        }

        if entry.isNewlyAccessible {
            score = score.adding(
                value: 25,
                name: "newly_accessible",
                detail: "Path becomes accessible under the proposed policy."
            )
        }

        let severity = PathSensitivitySeverity.highest(
            matchedRules.map(\.severity)
        )
        let action = PathSensitivityAction.strongest(
            matchedRules.map(\.action)
        )
        let strongestRule = matchedRules.sorted {
            if $0.severity.weight != $1.severity.weight {
                return $0.severity.weight > $1.severity.weight
            }

            return $0.score > $1.score
        }.first

        return .init(
            path: entry.path,
            type: entry.type,
            status: entry.status,
            matchedRuleIDs: matchedRules.map(\.id).sorted(),
            severity: severity,
            score: score,
            reason: matchedRules.map(\.reason).uniqued().joined(separator: " "),
            action: action,
            suggestedDenyRule: strongestRule.flatMap {
                denyRule(
                    for: $0,
                    path: entry.path,
                    type: entry.type
                )
            }
        )
    }

    static func groupedFindings(
        _ findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> [PathExposureGroup] {
        let grouped = Dictionary(
            grouping: findings
        ) {
            $0.path.parentKey
        }

        return grouped.keys.sorted().compactMap { key in
            guard let values = grouped[key],
                  let first = values.first else {
                return nil
            }

            let suggestion = PathDenySuggestionBuilder.parentSuggestion(
                parent: first.path.parentPath,
                findings: values,
                entries: entries,
                configuration: configuration
            )

            return .init(
                parentPath: first.path.parentPath,
                count: values.count,
                highestSeverity: .highest(
                    values.map(\.severity)
                ),
                commonPatternSuggestion: suggestion,
                findings: values.sorted {
                    $0.path.presentingRelative(filetype: true) < $1.path.presentingRelative(filetype: true)
                }
            )
        }
    }

    static func denyRule(
        for rule: PathSensitivityRule,
        path: ScopedPath,
        type: PathSegmentType
    ) -> PathAccessRule? {
        guard let suggestion = rule.suggestedDeny else {
            return nil
        }

        switch suggestion {
        case .component:
            if case .component(let value) = rule.matcher {
                return .denyComponent(
                    value,
                    reason: rule.reason
                )
            }

        case .basename:
            if case .basename(let value) = rule.matcher {
                return .denyBasename(
                    value,
                    reason: rule.reason
                )
            }

        case .suffix:
            if case .suffix(let value) = rule.matcher {
                return .denySuffix(
                    value,
                    reason: rule.reason
                )
            }

        case .expression:
            if case .expression(let expression) = rule.matcher {
                return .denyExpression(
                    expression,
                    reason: rule.reason
                )
            }

        case .parent:
            return parentDenyRule(
                for: path,
                reason: rule.reason
            )

        case .exact_path:
            return exactPathDenyRule(
                for: path,
                type: type,
                reason: rule.reason
            )
        }

        return exactPathDenyRule(
            for: path,
            type: type,
            reason: rule.reason
        )
    }

    static func parentDenyRule(
        for path: ScopedPath,
        reason: String?
    ) -> PathAccessRule? {
        guard let parent = path.parentPath else {
            return nil
        }

        let components = parent
            .presentingRelative(filetype: false)
            .split(separator: "/")
            .map {
                PathPatternComponent.literal(String($0))
            }

        guard !components.isEmpty else {
            return nil
        }

        return .denyExpression(
            PathExpression(
                pattern: PathPattern(
                    components + [
                        .recursive
                    ],
                    terminalHint: .unspecified
                )
            ),
            reason: reason
        )
    }

    static func exactPathDenyRule(
        for path: ScopedPath,
        type: PathSegmentType,
        reason: String?
    ) -> PathAccessRule {
        let terminalHint: PathTerminalHint

        switch type {
        case .file:
            terminalHint = .file

        case .directory:
            terminalHint = .directory
        }

        let components = path
            .presentingRelative(filetype: true)
            .split(separator: "/")
            .map {
                PathPatternComponent.literal(String($0))
            }

        return .denyExpression(
            PathExpression(
                pattern: PathPattern(
                    components,
                    terminalHint: terminalHint
                )
            ),
            reason: reason
        )
    }
}

private enum PathDenySuggestionBuilder {
    static func suggestions(
        findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> [PathDenySuggestion] {
        var suggestions: [PathDenySuggestion] = []

        suggestions.append(
            contentsOf: directSuggestions(
                findings: findings,
                entries: entries,
                configuration: configuration
            )
        )

        suggestions.append(
            contentsOf: parentSuggestions(
                findings: findings,
                entries: entries,
                configuration: configuration
            )
        )

        return suggestions
            .deduplicatedSuggestions()
            .sorted {
                if $0.score.value != $1.score.value {
                    return $0.score.value > $1.score.value
                }

                if $0.collateralCount != $1.collateralCount {
                    return $0.collateralCount < $1.collateralCount
                }

                if $0.coverageCount != $1.coverageCount {
                    return $0.coverageCount > $1.coverageCount
                }

                return $0.rule.matcher.summary < $1.rule.matcher.summary
            }
    }

    static func directSuggestions(
        findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> [PathDenySuggestion] {
        let rules = findings.compactMap(\.suggestedDenyRule)

        return Dictionary(
            grouping: rules,
            by: {
                $0.matcher.summary
            }
        ).values.compactMap { groupedRules in
            guard let rule = groupedRules.first else {
                return nil
            }

            return suggestion(
                kind: inferredKind(
                    for: rule
                ),
                rule: rule,
                findings: findings,
                entries: entries,
                configuration: configuration
            )
        }
    }

    static func parentSuggestions(
        findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> [PathDenySuggestion] {
        let grouped = Dictionary(
            grouping: findings
        ) {
            $0.path.parentKey
        }

        return grouped.values.compactMap { values in
            guard let first = values.first else {
                return nil
            }

            return parentSuggestion(
                parent: first.path.parentPath,
                findings: values,
                entries: entries,
                configuration: configuration
            )
        }
    }

    static func parentSuggestion(
        parent: ScopedPath?,
        findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> PathDenySuggestion? {
        guard let parent,
              findings.count > 1,
              let rule = PathExposureScan.parentDenyRule(
                for: parent.childSentinel,
                reason: "Deny sensitive parent cluster."
              ) else {
            return nil
        }

        guard let suggestion = suggestion(
            kind: .parent,
            rule: rule,
            findings: findings,
            entries: entries,
            configuration: configuration
        ) else {
            return nil
        }

        guard suggestion.collateralCount == 0 else {
            return nil
        }

        return suggestion
    }

    static func suggestion(
        kind: PathDenySuggestionKind,
        rule: PathAccessRule,
        findings: [PathExposureFinding],
        entries: [PathExposureEntry],
        configuration: PathExposureScanConfiguration
    ) -> PathDenySuggestion? {
        let coveredFindings = findings.filter {
            rule.matches(
                $0.path,
                type: $0.type
            )
        }

        guard !coveredFindings.isEmpty else {
            return nil
        }

        let coveredPaths = Set(
            coveredFindings.map(\.path)
        )

        let collateral = entries.filter {
            rule.matches(
                $0.path,
                type: $0.type
            ) && !coveredPaths.contains($0.path)
        }

        let confidence: PathDenySuggestionConfidence
        if collateral.isEmpty, coveredFindings.count > 1 {
            confidence = .high
        } else if collateral.isEmpty {
            confidence = .medium
        } else {
            confidence = .low
        }

        let severityWeight = coveredFindings.reduce(into: 0) { partial, finding in
            partial += finding.severity.weight
        }

        let score = PathDenySuggestionScore.zero
            .adding(
                value: coveredFindings.count * 100,
                name: "coverage",
                detail: "\(coveredFindings.count) finding(s)"
            )
            .adding(
                value: severityWeight * 20,
                name: "severity",
                detail: "Combined severity weight \(severityWeight)"
            )
            .adding(
                value: 0 - collateral.count * 80,
                name: "collateral",
                detail: "\(collateral.count) collateral path(s)"
            )

        return .init(
            kind: kind,
            rule: rule,
            coverageCount: coveredFindings.count,
            collateralCount: collateral.count,
            collateralExamples: Array(
                collateral
                    .map(\.path)
                    .prefix(configuration.maxCollateralExamples)
            ),
            confidence: confidence,
            score: score,
            reason: "Deny \(rule.matcher.summary) covers \(coveredFindings.count) sensitive finding(s) with \(collateral.count) collateral path(s)."
        )
    }

    static func inferredKind(
        for rule: PathAccessRule
    ) -> PathDenySuggestionKind {
        switch rule.matcher {
        case .component:
            return .component

        case .basename:
            return .basename

        case .suffix:
            return .suffix

        case .expression:
            return .expression
        }
    }
}

private extension ScopedPath {
    var hasHiddenComponent: Bool {
        relative.segments.contains {
            $0.value.hasPrefix(".")
        }
    }

    var parentPath: ScopedPath? {
        guard let parent = relative.parent(),
              !parent.segments.isEmpty else {
            return nil
        }

        return ScopedPath(
            root: root,
            relative: parent
        )
    }

    var parentKey: String {
        parentPath?.presentingRelative(filetype: false) ?? ""
    }

    var childSentinel: ScopedPath {
        let sentinel = StandardPath(
            from: relative,
            [
                "__path_exposure_child__"
            ],
            filetype: nil
        )

        return ScopedPath(
            root: root,
            relative: sentinel
        )
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        var out: [String] = []

        for value in self {
            guard seen.insert(value).inserted else {
                continue
            }

            out.append(value)
        }

        return out
    }
}

private extension Array where Element == PathDenySuggestion {
    func deduplicatedSuggestions() -> [PathDenySuggestion] {
        var seen = Set<String>()
        var out: [PathDenySuggestion] = []

        for suggestion in self {
            let key = suggestion.rule.matcher.summary

            guard seen.insert(key).inserted else {
                continue
            }

            out.append(suggestion)
        }

        return out
    }
}
