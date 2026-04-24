public enum PathSensitivityAction: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case warn_only
    case suggest_deny
    case require_deny
}

public extension PathSensitivityAction {
    var priority: Int {
        switch self {
        case .warn_only:
            return 1

        case .suggest_deny:
            return 2

        case .require_deny:
            return 3
        }
    }

    static func strongest(
        _ values: [Self]
    ) -> Self {
        values.max {
            $0.priority < $1.priority
        } ?? .warn_only
    }
}

public struct PathSensitivityRule: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var id: String
    public var matcher: PathAccessMatcher
    public var severity: PathSensitivitySeverity
    public var score: Int
    public var reason: String
    public var action: PathSensitivityAction
    public var suggestedDeny: PathDenySuggestionKind?

    public init(
        id: String,
        matcher: PathAccessMatcher,
        severity: PathSensitivitySeverity,
        score: Int,
        reason: String,
        action: PathSensitivityAction,
        suggestedDeny: PathDenySuggestionKind? = nil
    ) {
        self.id = id
        self.matcher = matcher
        self.severity = severity
        self.score = score
        self.reason = reason
        self.action = action
        self.suggestedDeny = suggestedDeny
    }
}

public extension PathSensitivityRule {
    func matches(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        matcher.matches(
            path,
            type: type
        )
    }

    func scoreComponent() -> PathSensitivityScoreComponent {
        .init(
            name: id,
            value: score,
            detail: reason,
            source: .path
        )
    }
}

public extension PathSensitivityRule {
    static func component(
        _ value: String,
        id: String? = nil,
        severity: PathSensitivitySeverity,
        score: Int,
        reason: String,
        action: PathSensitivityAction,
        suggestedDeny: PathDenySuggestionKind? = .component
    ) -> Self {
        .init(
            id: id ?? "component:\(value)",
            matcher: .component(value),
            severity: severity,
            score: score,
            reason: reason,
            action: action,
            suggestedDeny: suggestedDeny
        )
    }

    static func basename(
        _ value: String,
        id: String? = nil,
        severity: PathSensitivitySeverity,
        score: Int,
        reason: String,
        action: PathSensitivityAction,
        suggestedDeny: PathDenySuggestionKind? = .basename
    ) -> Self {
        .init(
            id: id ?? "basename:\(value)",
            matcher: .basename(value),
            severity: severity,
            score: score,
            reason: reason,
            action: action,
            suggestedDeny: suggestedDeny
        )
    }

    static func suffix(
        _ value: String,
        id: String? = nil,
        severity: PathSensitivitySeverity,
        score: Int,
        reason: String,
        action: PathSensitivityAction,
        suggestedDeny: PathDenySuggestionKind? = .suffix
    ) -> Self {
        .init(
            id: id ?? "suffix:\(value)",
            matcher: .suffix(value),
            severity: severity,
            score: score,
            reason: reason,
            action: action,
            suggestedDeny: suggestedDeny
        )
    }
}
