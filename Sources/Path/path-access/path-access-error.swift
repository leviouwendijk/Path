import Foundation

public enum PathAccessError: Error, LocalizedError, Sendable, Equatable {
    case denied(PathAccessEvaluation)

    public var errorDescription: String? {
        switch self {
        case .denied(let evaluation):
            let path = evaluation.path.presentingRelative(
                filetype: true
            )

            if let reason = evaluation.matchedRule?.reason,
               !reason.isEmpty {
                return "Path access denied for \(path): \(reason)"
            }

            if let rule = evaluation.matchedRule {
                return "Path access denied for \(path) by rule \(rule.matcher.summary)"
            }

            return "Path access denied for \(path)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .denied(let evaluation):
            if let rule = evaluation.matchedRule {
                return "Matched access rule \(rule.matcher.summary) with decision \(rule.decision.rawValue)."
            }

            return "The path was denied by the effective access policy."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .denied:
            return "Adjust the effective access policy, or use a workspace rooted at a broader trusted directory."
        }
    }
}
